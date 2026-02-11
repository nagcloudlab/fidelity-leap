import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { FeedbackService } from '../services/feedback.service';

interface MoodOption {
  value: string;
  emoji: string;
  label: string;
}

@Component({
  selector: 'app-feedback-form',
  imports: [FormsModule],
  templateUrl: './feedback-form.html',
  styleUrl: './feedback-form.css',
})
export class FeedbackForm {
  private feedbackService = inject(FeedbackService);
  private router = inject(Router);

  moods: MoodOption[] = [
    { value: 'Happy', emoji: '\uD83D\uDE0A', label: 'Happy' },
    { value: 'Neutral', emoji: '\uD83D\uDE10', label: 'Neutral' },
    { value: 'Sad', emoji: '\uD83D\uDE1E', label: 'Sad' },
  ];

  selectedMood = '';
  rating = 0;
  hoverRating = 0;
  comment = '';
  errorMessage = signal('');
  loading = signal(false);

  selectMood(mood: string) {
    this.selectedMood = mood;
  }

  setRating(star: number) {
    this.rating = star;
  }

  setHover(star: number) {
    this.hoverRating = star;
  }

  clearHover() {
    this.hoverRating = 0;
  }

  getStars(): number[] {
    return [1, 2, 3, 4, 5];
  }

  onSubmit() {
    this.errorMessage.set('');

    if (!this.selectedMood) {
      this.errorMessage.set('Please select a mood.');
      return;
    }
    if (this.rating === 0) {
      this.errorMessage.set('Please select a rating.');
      return;
    }

    this.loading.set(true);
    this.feedbackService
      .create({ mood: this.selectedMood, rating: this.rating, comment: this.comment })
      .subscribe({
        next: () => {
          this.router.navigate(['/feedbacks']);
        },
        error: (err) => {
          this.loading.set(false);
          this.errorMessage.set(err.error?.message ?? 'Failed to submit feedback.');
        },
      });
  }
}
