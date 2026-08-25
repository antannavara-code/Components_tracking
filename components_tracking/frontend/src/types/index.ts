export interface Asset {
  id: number;
  asset_id: string;
  category: string;
  name: string;
  serial_number: string | null;
  model: string | null;
  status: string;
  condition_type: string;
  current_user_id: number | null;
  current_location_id: number | null;
  current_drone_id: number | null;
  project_id: number | null;
  remarks: string | null;
  created_at: string;
  updated_at: string;
  current_user: Employee | null;
  current_location: Location | null;
  current_drone: Drone | null;
  project: Project | null;
}

export interface Employee {
  id: number;
  name: string;
  email: string;
  department: string | null;
  phone: string | null;
}

export interface Drone {
  id: number;
  drone_id: string;
  name: string;
  model: string | null;
  status: string;
  description: string | null;
}

export interface Location {
  id: number;
  name: string;
  building: string | null;
  room: string | null;
  description: string | null;
}

export interface Project {
  id: number;
  name: string;
  description: string | null;
  status: string;
}

export interface Movement {
  id: number;
  asset_id: number;
  action: string;
  from_user_id: number | null;
  to_user_id: number | null;
  from_location_id: number | null;
  to_location_id: number | null;
  from_drone_id: number | null;
  to_drone_id: number | null;
  from_status: string | null;
  to_status: string | null;
  purpose: string | null;
  remarks: string | null;
  performed_by: number | null;
  created_at: string;
}

export interface DashboardStats {
  total_assets: number;
  available: number;
  assigned: number;
  in_drone: number;
  testing: number;
  maintenance: number;
  missing: number;
  damaged: number;
}

export interface User {
  id: number;
  username: string;
  role: string;
  employee_id: number | null;
}

export interface Token {
  access_token: string;
  token_type: string;
  user: User;
}
