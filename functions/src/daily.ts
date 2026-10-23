import { createHash } from 'node:crypto';

/** Shared deterministic seed for a UTC daily challenge. */
export function dailySeed(dayKey: string): number {
  return createHash('sha256')
    .update(`clearway:${dayKey}`, 'utf8')
    .digest()
    .readUInt32BE(0);
}
