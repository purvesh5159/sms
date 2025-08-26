import bcrypt from 'bcryptjs';

export async function hashPassword(plain) {
	const salt = await bcrypt.genSalt(10);
	return bcrypt.hash(plain, salt);
}

export async function verifyPassword(plain, hash) {
	if (!hash) return false;
	try {
		return await bcrypt.compare(plain, hash);
	} catch (e) {
		return false;
	}
}