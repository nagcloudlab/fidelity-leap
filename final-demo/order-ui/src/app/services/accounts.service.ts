import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Account {
  id: number;
  customerName: string;
  customerEmail: string;
  balance: number;
}

export interface BalanceResponse {
  email: string;
  customerName: string;
  balance: number;
  sufficient: boolean;
}

@Injectable({ providedIn: 'root' })
export class AccountsService {
  private readonly API = 'http://localhost:8086/api/v1/accounts';

  constructor(private http: HttpClient) {}

  getAllAccounts(): Observable<Account[]> {
    return this.http.get<Account[]>(this.API);
  }

  getAccount(email: string): Observable<BalanceResponse> {
    return this.http.get<BalanceResponse>(`${this.API}/${email}/check?amount=0`);
  }

  checkBalance(email: string, amount: number): Observable<BalanceResponse> {
    return this.http.get<BalanceResponse>(`${this.API}/${email}/check?amount=${amount}`);
  }
}
