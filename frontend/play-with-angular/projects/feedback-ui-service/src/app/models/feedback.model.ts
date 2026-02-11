export interface FeedbackRequest {
  mood: string;
  rating: number;
  comment: string;
}

export interface FeedbackResponse {
  id: number;
  mood: string;
  rating: number;
  comment: string;
  createdAt: string;
  username: string;
}

export interface ErrorResponse {
  timestamp: string;
  status: number;
  error: string;
  message: string;
  path: string;
}
