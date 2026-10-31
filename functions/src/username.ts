const USERNAME_PATTERN = /^[A-Za-z0-9_]{3,15}$/;

export const RESERVED_USERNAMES: ReadonlySet<string> = new Set([
  'admin',
  'administrator',
  'clearway',
  'moderator',
  'official',
  'root',
  'staff',
  'support',
  'system',
]);

export type NormalizedUsername = {
  readonly display: string;
  readonly key: string;
};

/** Same rules as the app: 3-15 letters, numbers or underscore. */
export function normalizeUsername(value: unknown): NormalizedUsername {
  if (typeof value !== 'string' || !USERNAME_PATTERN.test(value)) {
    throw new Error('invalid-username');
  }
  return { display: value, key: value.toLowerCase() };
}
