import { v4 as uuidv4 } from 'uuid';
import crypto from 'crypto';

export default (seed) => {
    const buffer = crypto.createHash('sha256').update(seed).digest();
    const seed_16_bytes = buffer.subarray(0, 16);
    return uuidv4({ random: seed_16_bytes });
}
