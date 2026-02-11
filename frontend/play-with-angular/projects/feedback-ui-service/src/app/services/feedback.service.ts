import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { FeedbackRequest, FeedbackResponse } from '../models/feedback.model';

@Injectable({ providedIn: 'root' })
export class FeedbackService {
  private readonly API = 'http://localhost:8080/api/v1/feedbacks';

  constructor(private http: HttpClient) {}

  getAll(): Observable<FeedbackResponse[]> {
    return this.http.get<FeedbackResponse[]>(this.API);
  }

  create(feedback: FeedbackRequest): Observable<FeedbackResponse> {
    return this.http.post<FeedbackResponse>(this.API, feedback);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.API}/${id}`);
  }
}
