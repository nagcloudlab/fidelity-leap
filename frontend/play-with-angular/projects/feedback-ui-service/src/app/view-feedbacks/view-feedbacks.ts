import { Component, inject, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { FeedbackService } from '../services/feedback.service';
import { AuthService } from '../services/auth.service';
import { FeedbackResponse } from '../models/feedback.model';

@Component({
  selector: 'app-view-feedbacks',
  imports: [RouterLink],
  templateUrl: './view-feedbacks.html',
  styleUrl: './view-feedbacks.css',
})
export class ViewFeedbacks implements OnInit {
  private feedbackService = inject(FeedbackService);
  auth = inject(AuthService);

  feedbacks = signal<FeedbackResponse[]>([]);
  loading = signal(true);
  errorMessage = signal('');

  ngOnInit() {
    this.loadFeedbacks();
  }

  loadFeedbacks() {
    this.loading.set(true);
    this.errorMessage.set('');
    this.feedbackService.getAll().subscribe({
      next: (data) => {
        this.feedbacks.set(data);
        this.loading.set(false);
      },
      error: (err) => {
        this.errorMessage.set(err.error?.message ?? 'Failed to load feedbacks.');
        this.loading.set(false);
      },
    });
  }

  deleteFeedback(id: number) {
    this.feedbackService.delete(id).subscribe({
      next: () => {
        this.feedbacks.update((list) => list.filter((f) => f.id !== id));
      },
      error: (err) => {
        this.errorMessage.set(err.error?.message ?? 'Failed to delete feedback.');
      },
    });
  }

  getMoodEmoji(mood: string): string {
    switch (mood) {
      case 'Happy':
        return '\uD83D\uDE0A';
      case 'Neutral':
        return '\uD83D\uDE10';
      case 'Sad':
        return '\uD83D\uDE1E';
      default:
        return '\uD83D\uDE10';
    }
  }

  getMoodClass(mood: string): string {
    switch (mood) {
      case 'Happy':
        return 'bg-success-subtle text-success';
      case 'Neutral':
        return 'bg-warning-subtle text-warning';
      case 'Sad':
        return 'bg-danger-subtle text-danger';
      default:
        return 'bg-secondary-subtle text-secondary';
    }
  }

  getStarsArray(rating: number): boolean[] {
    return Array.from({ length: 5 }, (_, i) => i < rating);
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }
}
