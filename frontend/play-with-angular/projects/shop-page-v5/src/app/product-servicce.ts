import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class ProductServicce {

  apiUrl = 'http://localhost:8080/api/v1/products';

  constructor(private httpClient: HttpClient) { }

  getProductsByCategory(category: string): Observable<any[]> {
    console.log('Fetching products for category:', category);
    return this.httpClient.get<any[]>(`${this.apiUrl}?category=${category}`);
  }

  getReviews(productId: number): Observable<any[]> {
    console.log('Fetching reviews for product ID:', productId);
    return this.httpClient.get<any[]>(`${this.apiUrl}/${productId}/reviews`);
  }

}
