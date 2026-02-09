import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { VotingBox } from './voting-box/voting-box';

@Component({
  selector: 'app-root',
  imports: [
    VotingBox
  ],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('thinking-in-angular');
}
