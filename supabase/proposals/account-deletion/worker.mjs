// Pure orchestration prototype. No HTTP handler, SDK, credential or network adapter.
// This file is intentionally outside supabase/functions and cannot be deployed as-is.
const productionRef = 'fcfmfpywpurrvppxdltm';
const phases = ['approved', 'frozen', 'redacted', 'storage_clean', 'auth_deleted', 'verified', 'completed'];
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const errorCodes = new Set(['DISABLED', 'INVALID_OPERATION', 'ENVIRONMENT_DENIED',
  'PROJECT_DENIED', 'INVALID_JOB', 'MISSING_LEASE', 'POLICY_NOT_APPROVED',
  'INVALID_REQUEST_VERSION', 'AUTHORIZATION_DENIED', 'STORAGE_NOT_EMPTY',
  'VERIFICATION_FAILED', 'CHECKPOINT_CONFLICT', 'ADAPTER_FAILED']);
const privateErrorCodes = new WeakMap();

export class DeletionError extends Error {
  constructor(code) {
    const safeCode = errorCodes.has(code) ? code : 'ADAPTER_FAILED';
    super(safeCode); this.name = 'DeletionError'; this.code = safeCode;
    privateErrorCodes.set(this, safeCode);
  }
}
function requireCondition(condition, code) {
  if (!condition) throw new DeletionError(code);
}
function validateJob(job, operationId) {
  requireCondition(job && job.id === operationId && typeof job.subject === 'string' && uuid.test(job.subject), 'INVALID_JOB');
  requireCondition(phases.includes(job.phase) && Number.isSafeInteger(job.revision) && job.revision >= 1, 'INVALID_JOB');
  requireCondition(typeof job.lease === 'string' && job.lease.length > 0, 'MISSING_LEASE');
  requireCondition(job.policyApproved === true && typeof job.policyVersion === 'string' && job.policyVersion.length > 0, 'POLICY_NOT_APPROVED');
  requireCondition(Number.isSafeInteger(job.requestVersion) && job.requestVersion > 0, 'INVALID_REQUEST_VERSION');
}
function scope(job) {
  // Never pass caller-supplied storage paths or identities to an adapter.
  return Object.freeze({ id: job.id, subject: job.subject, revision: job.revision,
    lease: job.lease, policyVersion: job.policyVersion, requestVersion: job.requestVersion });
}

/**
 * Every effect must be idempotent by operation ID and enforce the lease/fence
 * at the boundary. Checkpoint must compare revision+lease and journal atomically.
 * The future adapter is responsible for fresh admin/identity/policy checks,
 * SQL transactions, immutable Storage inventories and external-call fencing.
 */
export async function runDeletion(operationId, adapter, options = {}) {
  let job, releaseContext;
  try {
    requireCondition(options.enabled === true, 'DISABLED');
    requireCondition(typeof operationId === 'string' && uuid.test(operationId), 'INVALID_OPERATION');
    requireCondition(adapter && ['fixture', 'staging'].includes(adapter.environment), 'ENVIRONMENT_DENIED');
    requireCondition(typeof options.projectRef === 'string' && options.projectRef.length > 0 &&
      adapter.projectRef === options.projectRef && adapter.projectRef !== productionRef, 'PROJECT_DENIED');
    job = await adapter.claim(operationId);
    validateJob(job, operationId);
    releaseContext = scope(job);
    const originalSubject = job.subject, originalPolicy = job.policyVersion,
      originalRequest = job.requestVersion, lease = job.lease;
    if (job.phase === 'completed') {
      requireCondition(await adapter.authorize(scope(job)) === true, 'AUTHORIZATION_DENIED');
    }
    while (job.phase !== 'completed') {
      const context = scope(job);
      requireCondition(await adapter.authorize(context) === true, 'AUTHORIZATION_DENIED');
      // Authorize must also check frozen-account protection against old JWTs,
      // current request version, policy validity and current operation ownership.
      switch (job.phase) {
        case 'approved': await adapter.freeze(context); break;
        case 'frozen': await adapter.redactAndDetach(context); break;
        case 'redacted':
          await adapter.purgeVerifiedStorage(context);
          requireCondition(await adapter.storageIsEmpty(context) === true, 'STORAGE_NOT_EMPTY');
          break;
        case 'storage_clean':
          // A late object or incomplete freeze must prevent Auth deletion.
          requireCondition(await adapter.storageIsEmpty(context) === true, 'STORAGE_NOT_EMPTY');
          await adapter.deleteAuth(context);
          break;
        case 'auth_deleted':
          requireCondition(await adapter.verifyAbsenceAndSurvivorHistory(context) === true, 'VERIFICATION_FAILED');
          break;
        case 'verified':
          requireCondition(await adapter.verifyAbsenceAndSurvivorHistory(context) === true, 'VERIFICATION_FAILED');
          break;
      }
      const nextPhase = phases[phases.indexOf(job.phase) + 1];
      const next = await adapter.checkpoint(context, nextPhase);
      validateJob(next, operationId);
      requireCondition(next.phase === nextPhase && next.revision === job.revision + 1 &&
        next.subject === originalSubject && next.policyVersion === originalPolicy &&
        next.requestVersion === originalRequest && next.lease === lease, 'CHECKPOINT_CONFLICT');
      job = next;
      releaseContext = scope(job);
    }
    // Do not return subject, notes, object paths or service errors in logs/results.
    return Object.freeze({ operationId, phase: 'completed' });
  } catch (error) {
    if (error instanceof DeletionError) throw new DeletionError(privateErrorCodes.get(error));
    // An adapter failure could contain PII or a credential; never echo its text.
    throw new DeletionError('ADAPTER_FAILED');
  } finally {
    if (releaseContext) {
      try { await adapter.release(releaseContext); } catch { /* TTL/fencing must expire the lease. */ }
    }
  }
}
