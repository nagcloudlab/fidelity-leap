import { Component } from '@angular/core';

interface Feedback {
  id: number;
  mood: string;
  rating: number;
  comment: string;
  createdAt: string;
  username: string;
}

@Component({
  selector: 'app-view-feedbacks',
  imports: [],
  templateUrl: './view-feedbacks.html',
  styleUrl: './view-feedbacks.css',
})
export class ViewFeedbacks {
  feedbacks: Feedback[] = [
    {
      id: 1,
      mood: 'Happy',
      rating: 5,
      comment: 'Absolutely love this service! Everything works seamlessly.',
      createdAt: '2026-02-11T10:30:00',
      username: 'alice',
    },
    {
      id: 2,
      mood: 'Neutral',
      rating: 3,
      comment: 'It works fine but could use some UI improvements.',
      createdAt: '2026-02-10T14:15:00',
      username: 'bob',
    },
    {
      id: 3,
      mood: 'Happy',
      rating: 4,
      comment: 'Great experience overall. Fast and responsive.',
      createdAt: '2026-02-09T09:00:00',
      username: 'charlie',
    },
    {
      id: 4,
      mood: 'Sad',
      rating: 2,
      comment: 'Had trouble logging in a few times. Please fix the auth flow.',
      createdAt: '2026-02-08T18:45:00',
      username: 'diana',
    },
    {
      id: 5,
      mood: 'Happy',
      rating: 5,
      comment: 'Best feedback platform I have used. Clean and simple.',
      createdAt: '2026-02-07T12:00:00',
      username: 'alice',
    },
  ];

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
    return new Date(dateStr).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }
}
