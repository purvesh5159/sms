import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import * as SecureStore from 'expo-secure-store';
import { api } from '../lib/api';

type AuthContextType = {
	token: string | null;
	societyId: number | null;
	setSocietyId: (id: number | null) => void;
	login: (email: string, password?: string, societyId?: number) => Promise<boolean>;
	devLogin: (email: string, societyId?: number) => Promise<boolean>;
	logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType>({
	token: null,
	societyId: null,
	setSocietyId: () => {},
	login: async () => false,
	devLogin: async () => false,
	logout: async () => {}
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
	const [token, setToken] = useState<string | null>(null);
	const [societyId, setSocietyId] = useState<number | null>(1);

	useEffect(() => {
		(async () => {
			const t = await SecureStore.getItemAsync('token');
			const sid = await SecureStore.getItemAsync('societyId');
			if (t) setToken(t);
			if (sid) setSocietyId(Number(sid));
		})();
	}, []);

	useEffect(() => {
		api.setToken(token);
		api.setSocietyId(societyId || undefined);
	}, [token, societyId]);

	const value = useMemo<AuthContextType>(() => ({
		token,
		societyId,
		setSocietyId: async (id) => {
			setSocietyId(id);
			if (id == null) await SecureStore.deleteItemAsync('societyId');
			else await SecureStore.setItemAsync('societyId', String(id));
		},
		login: async (email, password, sid) => {
			try {
				const res = await api.post('/auth/login', { email, password, societyId: sid });
				if (res.token) {
					setToken(res.token);
					await SecureStore.setItemAsync('token', res.token);
					if (res.user?.societyId) {
						setSocietyId(res.user.societyId);
						await SecureStore.setItemAsync('societyId', String(res.user.societyId));
					}
					return true;
				}
			} catch (e) {}
			return false;
		},
		devLogin: async (email, sid) => {
			try {
				const res = await api.post('/auth/dev-login', { email, societyId: sid });
				if (res.token) {
					setToken(res.token);
					await SecureStore.setItemAsync('token', res.token);
					if (res.user?.societyId) {
						setSocietyId(Number(res.user.societyId));
						await SecureStore.setItemAsync('societyId', String(res.user.societyId));
					}
					return true;
				}
			} catch (e) {}
			return false;
		},
		logout: async () => {
			setToken(null);
			await SecureStore.deleteItemAsync('token');
		}
	}), [token, societyId]);

	return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);