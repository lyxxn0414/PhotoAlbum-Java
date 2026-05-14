package com.photoalbum.repository;

import com.photoalbum.model.Photo;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository interface for Photo entity operations
 */
@Repository
public interface PhotoRepository extends JpaRepository<Photo, String> {

    /**
     * Find all photos ordered by upload date (newest first)
     * @return List of photos ordered by upload date descending
     */
    @Query("SELECT p FROM Photo p ORDER BY p.uploadedAt DESC")
    List<Photo> findAllOrderByUploadedAtDesc();

    /**
     * Find photos uploaded before a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded before the given timestamp
     */
    @Query("SELECT p FROM Photo p WHERE p.uploadedAt < :uploadedAt ORDER BY p.uploadedAt DESC")
    List<Photo> findPhotosUploadedBefore(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos uploaded after a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded after the given timestamp
     */
    @Query("SELECT p FROM Photo p WHERE p.uploadedAt > :uploadedAt ORDER BY p.uploadedAt ASC")
    List<Photo> findPhotosUploadedAfter(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos by upload year and month
     * @param year The year to search for
     * @param month The month to search for
     * @return List of photos uploaded in the specified month
     */
    @Query("SELECT p FROM Photo p WHERE YEAR(p.uploadedAt) = :year AND MONTH(p.uploadedAt) = :month ORDER BY p.uploadedAt DESC")
    List<Photo> findPhotosByUploadMonth(@Param("year") int year, @Param("month") int month);

    /**
     * Get paginated photos ordered by upload date descending
     * @param pageable Pageable object for offset/limit pagination
     * @return List of photos within the specified page
     */
    @Query("SELECT p FROM Photo p ORDER BY p.uploadedAt DESC")
    List<Photo> findPhotosWithPagination(Pageable pageable);

    /**
     * Find photos with file size statistics using window functions (PostgreSQL compatible)
     * @return List of photos with running totals and rankings
     */
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height, " +
                   "RANK() OVER (ORDER BY file_size DESC) as size_rank, " +
                   "SUM(file_size) OVER (ORDER BY uploaded_at ROWS UNBOUNDED PRECEDING) as running_total " +
                   "FROM photos " +
                   "ORDER BY uploaded_at DESC",
           nativeQuery = true)
    List<Object[]> findPhotosWithStatistics();
}