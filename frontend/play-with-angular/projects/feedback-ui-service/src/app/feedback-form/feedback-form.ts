import { Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

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
  successMessage = signal('');

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
    this.successMessage.set('');

    if (!this.selectedMood) {
      this.errorMessage.set('Please select a mood.');
      return;
    }
    if (this.rating === 0) {
      this.errorMessage.set('Please select a rating.');
      return;
    }

    // Static demo
    this.successMessage.set('Thank you! Your feedback has been submitted.');
    this.selectedMood = '';
    this.rating = 0;
    this.comment = '';
  }
}
