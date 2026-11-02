import test from 'node:test';
import assert from 'node:assert/strict';
import { runDeletion, DeletionError } from '../../supabase/proposals/account-deletion/worker.mjs';

const operation = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const subject = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const options = { enabled: true, projectRef: 'fixture-local' };
class Fixture {
  environment = 'fixture'; projectRef = 'fixture-local';
  job = { id: operation, subject, phase: 'approved', revision: 1, lease: 'fence-1', policyApproved: true, policyVersion: 'fixture-policy-v1', requestVersion: 8 };
  calls = []; effects = new Set(); checkpoints = []; failAt; failCheckpoint; revoked = false; empty = true; valid = true;
  async claim() { this.calls.push('claim'); return { ...this.job }; }
  async authorize(context) { this.calls.push('authorize'); return !this.revoked && context.lease === this.job.lease && context.revision === this.job.revision; }
  async effect(name, context) {
    assert.equal(context.subject, subject);
    assert.equal(Object.isFrozen(context), true);
    this.calls.push(name);
    if (this.failAt === name) throw new Error('fixture-sensitive-token@example.invalid');
    if (context.lease !== this.job.lease) throw new Error('fenced');
    this.effects.add(name); // Idempotent simulated external effects.
  }
  freeze(c) { return this.effect('freeze', c); }
  redactAndDetach(c) { return this.effect('redact', c); }
  purgeVerifiedStorage(c) { return this.effect('storage', c); }
  deleteAuth(c) { return this.effect('auth', c); }
  async storageIsEmpty() { this.calls.push('empty'); return this.empty; }
  async verifyAbsenceAndSurvivorHistory() { this.calls.push('verify'); return this.valid; }
  async checkpoint(c, phase) {
    if (this.failCheckpoint === phase) throw new Error('fixture journal unavailable');
    assert.equal(c.revision, this.job.revision);
    assert.equal(c.lease, this.job.lease);
    this.job = { ...this.job, phase, revision: c.revision + 1 };
    this.checkpoints.push(phase); return { ...this.job };
  }
  async release() { this.calls.push('release'); }
}
test('disabled by default and production/stale project cannot even claim a job', async () => {
  const a = new Fixture();
  await assert.rejects(runDeletion(operation, a), { code: 'DISABLED' });
  a.projectRef = 'fcfmfpywpurrvppxdltm';
  await assert.rejects(runDeletion(operation, a, { ...options, projectRef: a.projectRef }), { code: 'PROJECT_DENIED' });
  a.environment = 'production';
  await assert.rejects(runDeletion(operation, a, options), { code: 'ENVIRONMENT_DENIED' });
  assert.deepEqual(a.calls, []);
});
test('all phases ordered and result has no identity or content', async () => {
  const a = new Fixture(); const result = await runDeletion(operation, a, options);
  assert.deepEqual(a.checkpoints, ['frozen', 'redacted', 'storage_clean', 'auth_deleted', 'verified', 'completed']);
  assert.ok(a.calls.indexOf('redact') < a.calls.indexOf('auth'));
  assert.deepEqual(result, { operationId: operation, phase: 'completed' });
  assert.equal(JSON.stringify(result).includes(subject), false);
});
for (const phase of ['freeze', 'redact', 'storage', 'auth']) {
  test(`effect failure at ${phase} never reports completion, resuming is idempotent`, async () => {
    const a = new Fixture(); a.failAt = phase;
    await assert.rejects(runDeletion(operation, a, options), { code: 'ADAPTER_FAILED', message: 'ADAPTER_FAILED' });
    assert.notEqual(a.job.phase, 'completed');
    const effectsBefore = new Set(a.effects); a.failAt = undefined;
    await runDeletion(operation, a, options);
    assert.equal(a.job.phase, 'completed'); assert.equal(a.effects.size, 4);
    for (const effect of effectsBefore) assert.ok(a.effects.has(effect));
  });
}
test('journal failure after Auth side effect resumes from the last confirmed phase', async () => {
  const a = new Fixture(); a.failCheckpoint = 'auth_deleted';
  await assert.rejects(runDeletion(operation, a, options), { code: 'ADAPTER_FAILED' });
  assert.equal(a.job.phase, 'storage_clean'); assert.ok(a.effects.has('auth'));
  a.failCheckpoint = undefined; await runDeletion(operation, a, options);
  assert.equal(a.effects.size, 4); assert.equal(a.job.phase, 'completed');
});
test('Storage object remaining prevents Auth deletion', async () => {
  const a = new Fixture(); a.empty = false;
  await assert.rejects(runDeletion(operation, a, options), { code: 'STORAGE_NOT_EMPTY' });
  assert.equal(a.effects.has('auth'), false); assert.equal(a.job.phase, 'redacted');
});
test('failed post-deletion verification never closes an operation', async () => {
  const a = new Fixture(); a.valid = false;
  await assert.rejects(runDeletion(operation, a, options), { code: 'VERIFICATION_FAILED' });
  assert.equal(a.job.phase, 'auth_deleted'); assert.equal(a.checkpoints.includes('completed'), false);
});
test('revoked authorization blocks the next effect and releases the lease', async () => {
  const a = new Fixture(); a.revoked = true;
  await assert.rejects(runDeletion(operation, a, options), { code: 'AUTHORIZATION_DENIED' });
  assert.equal(a.effects.size, 0); assert.equal(a.calls.at(-1), 'release');
});
test('changed subject in a checkpoint is rejected before further destructive work', async () => {
  const a = new Fixture();
  const checkpoint = a.checkpoint.bind(a);
  a.checkpoint = async (...args) => ({ ...await checkpoint(...args), subject: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc' });
  await assert.rejects(runDeletion(operation, a, options), { code: 'CHECKPOINT_CONFLICT' });
  assert.equal(a.effects.has('auth'), false);
});
test('missing approved policy rejects the job before effects', async () => {
  const a = new Fixture(); a.job.policyApproved = false;
  await assert.rejects(runDeletion(operation, a, options), { code: 'POLICY_NOT_APPROVED' });
  assert.equal(a.effects.size, 0);
});
test('two competing leases cannot both progress', async () => {
  const a = new Fixture();
  a.authorize = async (c) => { a.job.lease = 'fence-2'; return c.lease === a.job.lease; };
  await assert.rejects(runDeletion(operation, a, options), { code: 'AUTHORIZATION_DENIED' });
  assert.equal(a.effects.size, 0);
});
test('malformed operation has no adapter side effects', async () => {
  const a = new Fixture(); await assert.rejects(runDeletion('../other-user', a, options), DeletionError);
  assert.deepEqual(a.calls, []);
});
test('a late Storage object just before Auth deletion blocks that call', async () => {
  const a = new Fixture(); let checks = 0;
  a.storageIsEmpty = async () => ++checks === 1;
  await assert.rejects(runDeletion(operation, a, options), { code: 'STORAGE_NOT_EMPTY' });
  assert.equal(a.job.phase, 'storage_clean'); assert.equal(a.effects.has('auth'), false);
});
test('a different policy returned by a checkpoint cannot progress', async () => {
  const a = new Fixture(); const checkpoint = a.checkpoint.bind(a);
  a.checkpoint = async (...args) => ({ ...await checkpoint(...args), policyVersion: 'unapproved-other-policy' });
  await assert.rejects(runDeletion(operation, a, options), { code: 'CHECKPOINT_CONFLICT' });
  assert.equal(a.effects.has('auth'), false);
});
test('completion is idempotent but still requires current authorization', async () => {
  const a = new Fixture(); await runDeletion(operation, a, options);
  const effectCount = a.calls.filter((c) => ['freeze','redact','storage','auth'].includes(c)).length;
  await runDeletion(operation, a, options);
  assert.equal(a.calls.filter((c) => ['freeze','redact','storage','auth'].includes(c)).length, effectCount);
  a.revoked = true;
  await assert.rejects(runDeletion(operation, a, options), { code: 'AUTHORIZATION_DENIED' });
});
test('a malformed claimed identity is never used to release another lease', async () => {
  const a = new Fixture(); a.job.id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  await assert.rejects(runDeletion(operation, a, options), { code: 'INVALID_JOB' });
  assert.equal(a.calls.includes('release'), false); assert.equal(a.effects.size, 0);
});
test('adapter configuration or custom errors cannot expose external sensitive text', async () => {
  const a = new Fixture();
  a.freeze = async () => { throw new DeletionError('fixture-private-secret@example.invalid'); };
  await assert.rejects(runDeletion(operation, a, options), { code: 'ADAPTER_FAILED', message: 'ADAPTER_FAILED' });
  a.freeze = async () => {
    const error = new DeletionError('AUTHORIZATION_DENIED');
    error.message = 'fixture-private-secret'; error.code = 'fixture-private-secret'; throw error;
  };
  await assert.rejects(runDeletion(operation, a, options), { code: 'AUTHORIZATION_DENIED', message: 'AUTHORIZATION_DENIED' });
  const broken = { get environment() { throw new Error('fixture-private-secret'); } };
  await assert.rejects(runDeletion(operation, broken, options), { code: 'ADAPTER_FAILED', message: 'ADAPTER_FAILED' });
});
