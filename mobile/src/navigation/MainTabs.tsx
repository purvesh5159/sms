import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { View, Text, Button, FlatList, TextInput, StyleSheet } from 'react-native';
import { useAuth } from '../context/AuthContext';
import { api } from '../lib/api';

const Tab = createBottomTabNavigator();
const Stack = createNativeStackNavigator();

function HomeScreen() {
	const { societyId } = useAuth();
	const [me, setMe] = React.useState<any>(null);
	React.useEffect(() => {
		api.get('/me/profile').then(setMe).catch(() => {});
	}, [societyId]);
	return (
		<View style={styles.container}>
			<Text style={styles.title}>Dashboard</Text>
			<Text>Society: {societyId}</Text>
			<Text>User: {me?.user?.full_name || '-'}</Text>
			<Text>Roles: {(me?.roles || []).join(', ')}</Text>
		</View>
	);
}

function TowersScreen() {
	const [items, setItems] = React.useState<any[]>([]);
	React.useEffect(() => { api.get('/towers').then(setItems).catch(() => {}); }, []);
	return (
		<FlatList data={items} keyExtractor={(i) => String(i.id)}
		renderItem={({ item }) => <View style={styles.listItem}><Text>{item.name}</Text><Text>{item.num_floors || '-'} floors</Text></View>} />
	);
}

function FlatsScreen() {
	const [items, setItems] = React.useState<any[]>([]);
	React.useEffect(() => { api.get('/flats').then(setItems).catch(() => {}); }, []);
	return (
		<FlatList data={items} keyExtractor={(i) => String(i.id)}
		renderItem={({ item }) => <View style={styles.listItem}><Text>{item.tower_name} - {item.number}</Text></View>} />
	);
}

function ComplaintsScreen() {
	const [items, setItems] = React.useState<any[]>([]);
	const [flatId, setFlatId] = React.useState('');
	const [category, setCategory] = React.useState('General');
	const [description, setDescription] = React.useState('');
	const load = React.useCallback(() => api.get('/complaints').then(setItems).catch(() => {}), []);
	React.useEffect(() => { load(); }, [load]);
	async function create() {
		try {
			await api.post('/complaints', { flatId: Number(flatId), category, description });
			setFlatId(''); setCategory('General'); setDescription('');
			load();
		} catch (e) { alert('Failed'); }
	}
	return (
		<View style={{ flex: 1 }}>
			<View style={{ padding: 12, gap: 8 }}>
				<TextInput placeholder='Flat ID' value={flatId} onChangeText={setFlatId} keyboardType='numeric' style={styles.input} />
				<TextInput placeholder='Category' value={category} onChangeText={setCategory} style={styles.input} />
				<TextInput placeholder='Description' value={description} onChangeText={setDescription} style={styles.input} />
				<Button title='Create' onPress={create} />
			</View>
			<FlatList data={items} keyExtractor={(i) => String(i.id)}
			renderItem={({ item }) => <View style={styles.listItem}><Text>{item.tower_name} {item.flat_number}</Text><Text>{item.category} - {item.status}</Text></View>} />
		</View>
	);
}

function SettingsScreen() {
	const { logout } = useAuth();
	return (
		<View style={styles.container}>
			<Button title='Logout' onPress={logout} />
		</View>
	);
}

export default function MainTabs() {
	return (
		<Tab.Navigator>
			<Tab.Screen name="Home" component={HomeScreen} />
			<Tab.Screen name="Towers" component={TowersScreen} />
			<Tab.Screen name="Flats" component={FlatsScreen} />
			<Tab.Screen name="Complaints" component={ComplaintsScreen} />
			<Tab.Screen name="Settings" component={SettingsScreen} />
		</Tab.Navigator>
	);
}

const styles = StyleSheet.create({
	container: { flex: 1, padding: 16 },
	title: { fontSize: 22, fontWeight: '600', marginBottom: 8 },
	listItem: { padding: 12, borderBottomWidth: 1, borderColor: '#eee' },
	input: { borderWidth: 1, borderColor: '#ccc', borderRadius: 8, padding: 10 }
});