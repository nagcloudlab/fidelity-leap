import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { OrderSummary, TopProduct, RecentOrder } from '../models/analytics.model';

@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private readonly API = 'http://localhost:8083/api/v1/analytics';

  constructor(private http: HttpClient) {}

  getSummary(): Observable<OrderSummary[]> {
    return this.http.get<OrderSummary[]>(`${this.API}/summary`);
  }

  getTopProducts(): Observable<TopProduct[]> {
    return this.http.get<TopProduct[]>(`${this.API}/top-products`);
  }

  getRecentOrders(): Observable<RecentOrder[]> {
    return this.http.get<RecentOrder[]>(`${this.API}/recent-orders`);
  }
}
