package com.example.repository;

import com.example.entity.Feedback;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Transactional
public interface FeedbackRepository extends JpaRepository<Feedback,Long> {

    @Query("from Feedback f where f.user.id=:userId")
    List<Feedback> findByUserId(Long userId);

}
