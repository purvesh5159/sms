import { DataTypes } from 'sequelize';
import { sequelize } from '../config/sequelize.js';

export const User = sequelize.define('users', {
	id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
	full_name: { type: DataTypes.STRING, allowNull: false },
	email: { type: DataTypes.STRING, allowNull: false },
	phone: { type: DataTypes.STRING },
	role: { type: DataTypes.ENUM('admin','secretary','resident','security','committee'), allowNull: false },
	password_hash: { type: DataTypes.TEXT, allowNull: false },
	is_active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
	created_at: { type: DataTypes.DATE },
	updated_at: { type: DataTypes.DATE },
}, { tableName: 'users' });

export const Society = sequelize.define('societies', {
	id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
	name: { type: DataTypes.STRING, allowNull: false },
	code: { type: DataTypes.STRING },
}, { tableName: 'societies' });

export const Role = sequelize.define('roles', {
	id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
	society_id: { type: DataTypes.BIGINT, allowNull: false },
	name: { type: DataTypes.STRING, allowNull: false },
}, { tableName: 'roles' });

export const Permission = sequelize.define('permissions', {
	id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
	module: { type: DataTypes.STRING, allowNull: false },
	action: { type: DataTypes.STRING, allowNull: false },
}, { tableName: 'permissions' });

export const RolePermission = sequelize.define('role_permissions', {
	role_id: { type: DataTypes.BIGINT, primaryKey: true },
	permission_id: { type: DataTypes.BIGINT, primaryKey: true },
}, { tableName: 'role_permissions' });

export const SocietyMembership = sequelize.define('society_memberships', {
	id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
	society_id: { type: DataTypes.BIGINT, allowNull: false },
	user_id: { type: DataTypes.BIGINT, allowNull: false },
	is_active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
}, { tableName: 'society_memberships' });

export const SocietyUserRole = sequelize.define('society_user_roles', {
	membership_id: { type: DataTypes.BIGINT, primaryKey: true },
	role_id: { type: DataTypes.BIGINT, primaryKey: true },
	society_id: { type: DataTypes.BIGINT, allowNull: false },
}, { tableName: 'society_user_roles' });

export const Tower = sequelize.define('towers', {
	id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
	society_id: { type: DataTypes.BIGINT, allowNull: false },
	name: { type: DataTypes.STRING, allowNull: false },
}, { tableName: 'towers' });

export const Flat = sequelize.define('flats', {
	id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
	society_id: { type: DataTypes.BIGINT, allowNull: false },
	tower_id: { type: DataTypes.BIGINT, allowNull: false },
	number: { type: DataTypes.STRING, allowNull: false },
	floor: { type: DataTypes.INTEGER },
}, { tableName: 'flats' });

export const Complaint = sequelize.define('complaints', {
	id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
	society_id: { type: DataTypes.BIGINT, allowNull: false },
	flat_id: { type: DataTypes.BIGINT, allowNull: false },
	created_by_user_id: { type: DataTypes.BIGINT },
	assigned_to_user_id: { type: DataTypes.BIGINT },
	category: { type: DataTypes.STRING, allowNull: false },
	description: { type: DataTypes.TEXT, allowNull: false },
	status: { type: DataTypes.ENUM('open','in_progress','closed'), defaultValue: 'open' },
	priority: { type: DataTypes.SMALLINT, defaultValue: 3 },
	created_at: { type: DataTypes.DATE },
	updated_at: { type: DataTypes.DATE },
}, { tableName: 'complaints' });