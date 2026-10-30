export type EconomyItem = {
  readonly id: string;
  readonly cost: number;
  readonly hints: number;
  readonly undos: number;
  readonly skinId?: string;
};

export const ECONOMY_ITEMS: readonly EconomyItem[] = [
  { id: 'hint-pack', cost: 50, hints: 2, undos: 0 },
  { id: 'undo-pack', cost: 30, hints: 0, undos: 3 },
  { id: 'sunset-skin', cost: 150, hints: 0, undos: 0, skinId: 'sunset' },
];

export function economyItem(id: unknown): EconomyItem {
  if (typeof id !== 'string') throw new Error('invalid-item');
  const item = ECONOMY_ITEMS.find((candidate) => candidate.id === id);
  if (!item) throw new Error('invalid-item');
  return item;
}

export function safeBalance(value: unknown): number {
  if (value === undefined || value === null) return 0;
  if (
    typeof value !== 'number' ||
    !Number.isSafeInteger(value) ||
    value < 0
  ) {
    throw new Error('invalid-balance');
  }
  return value;
}

export function requestId(value: unknown): string {
  if (
    typeof value !== 'string' ||
    value.length < 8 ||
    value.length > 128 ||
    !/^[A-Za-z0-9._:-]+$/.test(value)
  ) {
    throw new Error('invalid-request-id');
  }
  return value;
}

export function boundedAmount(value: unknown): number {
  if (
    typeof value !== 'number' ||
    !Number.isSafeInteger(value) ||
    value < 1 ||
    value > 1000
  ) {
    throw new Error('invalid-amount');
  }
  return value;
}

export const AD_COINS_REWARD = 30;
export const AD_COINS_PER_DAY = 5;
