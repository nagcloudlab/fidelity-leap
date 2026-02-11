import { Routes } from '@angular/router';
import { Home } from './home/home';
import { Login } from './login/login';
import { Register } from './register/register';
import { FeedbackForm } from './feedback-form/feedback-form';
import { ViewFeedbacks } from './view-feedbacks/view-feedbacks';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: '', component: Home },
  { path: 'login', component: Login },
  { path: 'register', component: Register },
  { path: 'feedback', component: FeedbackForm, canActivate: [authGuard] },
  { path: 'feedbacks', component: ViewFeedbacks, canActivate: [authGuard] },
  { path: '**', redirectTo: '' },
];
