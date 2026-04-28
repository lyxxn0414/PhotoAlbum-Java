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
                   "OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedBefore(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos uploaded after a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded after the given timestamp
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, " +
                   "ISNULL(FILE_PATH, 'default_path') AS FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "WHERE UPLOADED_AT > :uploadedAt " +
                   "ORDER BY UPLOADED_AT ASC", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedAfter(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos by upload month using YEAR() and MONTH() functions - Azure SQL compatible
     * @param year The year to search for
     * @param month The month to search for
     * @return List of photos uploaded in the specified month
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "WHERE CAST(YEAR(UPLOADED_AT) AS VARCHAR) = :year " +
                   "AND RIGHT('0' + CAST(MONTH(UPLOADED_AT) AS VARCHAR), 2) = :month " +
                   "ORDER BY UPLOADED_AT DESC", 
           nativeQuery = true)
    List<Photo> findPhotosByUploadMonth(@Param("year") String year, @Param("month") String month);

    /**
     * Get paginated photos using OFFSET/FETCH - Azure SQL compatible pagination
     * @param offset The number of rows to skip (0-based)
     * @param pageSize The number of rows to fetch
     * @return List of photos within the specified page
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "ORDER BY UPLOADED_AT DESC " +
                   "OFFSET :offset ROWS FETCH NEXT :pageSize ROWS ONLY", 
           nativeQuery = true)
    List<Photo> findPhotosWithPagination(@Param("offset") int offset, @Param("pageSize") int pageSize);

    /**
     * Find photos with file size statistics using window functions - Azure SQL compatible
     * @return List of photos with running totals and rankings
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT, " +
                   "RANK() OVER (ORDER BY FILE_SIZE DESC) AS SIZE_RANK, " +
                   "SUM(FILE_SIZE) OVER (ORDER BY UPLOADED_AT ROWS UNBOUNDED PRECEDING) AS RUNNING_TOTAL " +
                   "FROM PHOTOS " +
                   "ORDER BY UPLOADED_AT DESC", 
           nativeQuery = true)
    List<Object[]> findPhotosWithStatistics();
}