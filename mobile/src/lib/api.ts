import axios, { AxiosInstance } from 'axios';

class ApiClient {
	private client: AxiosInstance;
	private token?: string;
	private societyId?: number;

	constructor() {
		this.client = axios.create({ baseURL: 'http://localhost:3001/api' });
		this.client.interceptors.request.use((config) => {
			if (this.token) config.headers = { ...config.headers, Authorization: `Bearer ${this.token}` };
			if (this.societyId) config.headers = { ...config.headers, 'X-Society-Id': String(this.societyId) };
			return config;
		});
		this.client.interceptors.response.use((res) => res.data, (err) => Promise.reject(err));
	}

	setToken(token?: string | null) {
		this.token = token || undefined;
	}

	setSocietyId(id?: number) {
		this.societyId = id;
	}

	get(path: string, params?: any) { return this.client.get(path, { params }); }
	post(path: string, data?: any) { return this.client.post(path, data); }
	patch(path: string, data?: any) { return this.client.patch(path, data); }
}

export const api = new ApiClient();