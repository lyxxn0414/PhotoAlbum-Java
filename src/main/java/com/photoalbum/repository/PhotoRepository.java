package com.photoalbum.repository;

import com.photoalbum.model.Photo;
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
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "ORDER BY UPLOADED_AT DESC", 
           nativeQuery = true)
    List<Photo> findAllOrderByUploadedAtDesc();

    /**
     * Find photos uploaded before a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded before the given timestamp
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "WHERE UPLOADED_AT < :uploadedAt " +
                   "ORDER BY UPLOADED_AT DESC " +
                   "LIMIT 10",
           nativeQuery = true)
    List<Photo> findPhotosUploadedBefore(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos uploaded after a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded after the given timestamp
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, " +
                   "COALESCE(FILE_PATH, 'default_path') as FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "WHERE UPLOADED_AT > :uploadedAt " +
                   "ORDER BY UPLOADED_AT ASC", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedAfter(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos by upload month using PostgreSQL EXTRACT and LPAD functions
     * @param year The year to search for
     * @param month The month to search for (zero-padded, e.g. "01")
     * @return List of photos uploaded in the specified month
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "WHERE EXTRACT(YEAR FROM UPLOADED_AT)::text = :year " +
                   "AND LPAD(EXTRACT(MONTH FROM UPLOADED_AT)::text, 2, '0') = :month " +
                   "ORDER BY UPLOADED_AT DESC", 
           nativeQuery = true)
    List<Photo> findPhotosByUploadMonth(@Param("year") String year, @Param("month") String month);

    /**
     * Get paginated photos using PostgreSQL LIMIT/OFFSET
     * @param offset Starting row offset (0-based)
     * @param pageSize Number of rows to return
     * @return List of photos within the specified page range
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS ORDER BY UPLOADED_AT DESC " +
                   "LIMIT :pageSize OFFSET :offset", 
           nativeQuery = true)
    List<Photo> findPhotosWithPagination(@Param("offset") int offset, @Param("pageSize") int pageSize);

    /**
     * Find photos with file size statistics using Oracle analytical functions - Oracle specific
     * @return List of photos with running totals and rankings
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT, " +
                   "RANK() OVER (ORDER BY FILE_SIZE DESC) as SIZE_RANK, " +
                   "SUM(FILE_SIZE) OVER (ORDER BY UPLOADED_AT ROWS UNBOUNDED PRECEDING) as RUNNING_TOTAL " +
                   "FROM PHOTOS " +
                   "ORDER BY UPLOADED_AT DESC", 
           nativeQuery = true)
    List<Object[]> findPhotosWithStatistics();
}