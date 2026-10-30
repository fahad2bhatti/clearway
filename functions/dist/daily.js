"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.dailySeed = void 0;
const node_crypto_1 = require("node:crypto");
function dailySeed(dayKey) {
    return (0, node_crypto_1.createHash)('sha256')
        .update(`clearway:${dayKey}`, 'utf8')
        .digest()
        .readUInt32BE(0);
}
exports.dailySeed = dailySeed;
