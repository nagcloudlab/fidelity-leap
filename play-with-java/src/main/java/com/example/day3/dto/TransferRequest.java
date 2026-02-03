package com.example.day3.dto;

public class TransferRequest {
    private String fromAccountId;
    private String toAccountId;
    private double amount;

    public TransferRequest() {
    }

    public TransferRequest(String fromAccountId, String toAccountId, double amount) {
        this.fromAccountId = fromAccountId;
        this.toAccountId = toAccountId;
        this.amount = amount;
    }

    public String getFromAccountId() {
        return fromAccountId;
    }

    public void setFromAccountId(String fromAccountId) {
        this.fromAccountId = fromAccountId;
    }

    public String getToAccountId() {
        return toAccountId;
    }

    public void setToAccountId(String toAccountId) {
        this.toAccountId = toAccountId;
    }

    public double getAmount() {
        return amount;
    }

    public void setAmount(double amount) {
        this.amount = amount;
    }

    //hashCode and equals methods
    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((fromAccountId == null) ? 0 : fromAccountId.hashCode());
        result = prime * result + ((toAccountId == null) ? 0 : toAccountId.hashCode());
        long temp;
        temp = Double.doubleToLongBits(amount);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        TransferRequest other = (TransferRequest) obj;
        if (fromAccountId == null) {
            if (other.fromAccountId != null)
                return false;
        } else if (!fromAccountId.equals(other.fromAccountId))
            return false;
        if (toAccountId == null) {
            if (other.toAccountId != null)
                return false;
        } else if (!toAccountId.equals(other.toAccountId))
            return false;
        if (Double.doubleToLongBits(amount) != Double.doubleToLongBits(other.amount))
            return false;
        return true;
    }

    // toString method
    @Override
    public String toString() {
        return "TransferRequest [fromAccountId=" + fromAccountId + ", toAccountId=" + toAccountId + ", amount=" + amount + "]";
    }

}
