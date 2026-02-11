import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import {
  RegisterRequest,
  RegisterResponse,
  LoginRequest,
  LoginResponse,
  JwtPayload,
} from '../models/auth.model';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly API = 'http://localhost:8080';
  private readonly TOKEN_KEY = 'jwt_token';

  private loggedIn = signal(this.hasToken());
  private currentUser = signal(this.decodeStoredToken());

  isLoggedIn = this.loggedIn.asReadonly();
  username = computed(() => this.currentUser()?.sub ?? '');
  userId = computed(() => this.currentUser()?.userId ?? 0);
  role = computed(() => this.currentUser()?.role ?? '');
  isAdmin = computed(() => this.role() === 'ADMIN');

  constructor(private http: HttpClient) {}

  register(req: RegisterRequest): Observable<RegisterResponse> {
    return this.http.post<RegisterResponse>(`${this.API}/register`, req);
  }

  login(req: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.API}/login`, req).pipe(
      tap((res) => {
        localStorage.setItem(this.TOKEN_KEY, res.token);
        this.currentUser.set(this.decodeToken(res.token));
        this.loggedIn.set(true);
      }),
    );
  }

  logout(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    this.currentUser.set(null);
    this.loggedIn.set(false);
  }

  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }

  private hasToken(): boolean {
    const token = localStorage.getItem(this.TOKEN_KEY);
    if (!token) return false;
    const payload = this.decodeToken(token);
    if (!payload) return false;
    return payload.exp * 1000 > Date.now();
  }

  private decodeStoredToken(): JwtPayload | null {
    const token = localStorage.getItem(this.TOKEN_KEY);
    if (!token) return null;
    const payload = this.decodeToken(token);
    if (!payload || payload.exp * 1000 < Date.now()) {
      localStorage.removeItem(this.TOKEN_KEY);
      return null;
    }
    return payload;
  }

  private decodeToken(token: string): JwtPayload | null {
    try {
      const payload = token.split('.')[1];
      return JSON.parse(atob(payload));
    } catch {
      return null;
    }
  }
}
