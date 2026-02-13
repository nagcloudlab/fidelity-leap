import { Component, inject, OnInit, signal } from '@angular/core';
import { AnalyticsService } from '../services/analytics.service';
import { OrderSummary, TopProduct, RecentOrder } from '../models/analytics.model';

@Component({
  selector: 'app-analytics-dashboard',
  imports: [],
  templateUrl: './analytics-dashboard.html',
  styleUrl: './analytics-dashboard.css',
})
export class AnalyticsDashboard implements OnInit {
  private analyticsService = inject(AnalyticsService);

  summary = signal<OrderSummary[]>([]);
  topProducts = signal<TopProduct[]>([]);
  recentOrders = signal<RecentOrder[]>([]);
  loading = signal(true);
  errorMessage = signal('');

  ngOnInit() {
    this.loadData();
  }

  loadData() {
    this.loading.set(true);
    this.errorMessage.set('');

    let completed = 0;
    const checkDone = () => {
      completed++;
      if (completed >= 3) this.loading.set(false);
    };

    this.analyticsService.getSummary().subscribe({
      next: (data) => this.summary.set(data),
      error: (err) => this.errorMessage.set('Failed to load analytics: ' + (err.error?.message ?? err.message)),
      complete: checkDone,
    });

    this.analyticsService.getTopProducts().subscribe({
      next: (data) => this.topProducts.set(data),
      error: () => {},
      complete: checkDone,
    });

    this.analyticsService.getRecentOrders().subscribe({
      next: (data) => this.recentOrders.set(data),
      error: () => {},
      complete: checkDone,
    });
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }
}
