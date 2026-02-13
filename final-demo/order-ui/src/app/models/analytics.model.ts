export interface OrderSummary {
  orderDay: string;
  totalOrders: number;
  totalRevenue: number;
  avgOrderValue: number;
  totalItems: number;
}

export interface TopProduct {
  productName: string;
  timesOrdered: number;
  totalUnitsSold: number;
  totalRevenue: number;
  avgUnitPrice: number;
}

export interface RecentOrder {
  orderId: number;
  customerName: string;
  customerEmail: string;
  orderDate: string;
  status: string;
  totalAmount: number;
  itemCount: number;
}
