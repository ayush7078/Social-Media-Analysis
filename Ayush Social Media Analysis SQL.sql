use ig_clone
--  Q1. Are there any tables with duplicate or missing null values? If so, how would you handle them?
-- Check for duplicates in users table

SELECT username, COUNT(*) AS duplicate_count
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- Check for null values in all tables
SELECT 
    (SELECT COUNT(*) FROM users WHERE username IS NULL) AS null_in_users,
    (SELECT COUNT(*) FROM photos WHERE image_url IS NULL) AS null_in_photos,
    (SELECT COUNT(*) FROM comments WHERE comment_text IS NULL) AS null_in_comments,
    (SELECT COUNT(*) FROM tags WHERE tag_name IS NULL) AS null_in_tags;

#Q2. What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

SELECT u.id AS user_id, u.username, 
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username;

#Q3. Calculate the average number of tags per post (photo_tags and photos tables).
SELECT AVG(tag_count) AS avg_tags_per_post
FROM (
    SELECT p.id, COUNT(pt.tag_id) AS tag_count
    FROM photos p
    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.id
) AS tag_stats;

#Q4. Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.
SELECT u.id AS user_id, u.username, 
    (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id)) / COUNT(DISTINCT p.id) AS engagement_rate
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
ORDER BY engagement_rate DESC
LIMIT 10;


#Q5. Which users have the highest number of followers and followings?
-- Highest followers
SELECT followee_id AS user_id, COUNT(follower_id) AS total_followers
FROM follows
GROUP BY followee_id
ORDER BY total_followers DESC
LIMIT 10;

-- Highest followings
SELECT follower_id AS user_id, COUNT(followee_id) AS total_followings
FROM follows
GROUP BY follower_id
ORDER BY total_followings DESC
LIMIT 10;

#Q6.Calculate the average engagement rate (likes, comments) per post for each user.
SELECT u.id AS user_id, u.username,
    AVG(like_count + comment_count) AS avg_engagement_rate
FROM users u
LEFT JOIN (
    SELECT p.user_id, p.id AS photo_id, 
        COUNT(DISTINCT l.user_id) AS like_count, 
        COUNT(DISTINCT c.id) AS comment_count
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.id
) AS engagement_stats ON u.id = engagement_stats.user_id
GROUP BY u.id, u.username;

#Q7. Get the list of users who have never liked any post (users and likes tables)
SELECT u.id, u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

#Q8. How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?
-- Most used hashtags
SELECT t.tag_name, COUNT(pt.photo_id) AS usage_count
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.tag_name
ORDER BY usage_count DESC
LIMIT 10;

-- Most engaged content types
SELECT p.id, COUNT(l.user_id) AS likes, COUNT(c.id) AS comments
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY p.id
ORDER BY (likes + comments) DESC;

#Q9. Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?
SELECT p.user_id, COUNT(DISTINCT p.id) AS photo_posts, 
    COUNT(DISTINCT l.photo_id) AS likes, 
    COUNT(DISTINCT c.id) AS comments
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY p.user_id;

#Q10. Calculate the total number of likes, comments, and photo tags for each user.
SELECT u.id AS user_id, u.username, 
    COUNT(DISTINCT l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    COUNT(DISTINCT pt.tag_id) AS total_tags
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
LEFT JOIN photo_tags pt ON p.id = pt.photo_id
GROUP BY u.id, u.username;

#Q11. Rank users based on their total engagement (likes, comments, shares) over a month.

    WITH Post_likes AS (SELECT distinct user_id, count(*) AS like_count
	FROM likes GROUP BY user_id),
     
	Post_comments AS (SELECT distinct user_id, count(*) AS comment_count
	FROM comments GROUP BY user_id),
	
	Total_likes_n_comments AS (
	  SELECT distinct u.id AS User_id, u.username,
                coalesce(pl.like_count, 0) AS like_count,
	            coalesce(pc.comment_count, 0) AS comment_count,
				coalesce(pl.like_count, 0) + coalesce(pc.comment_count, 0) AS total_engagement
      FROM users as u
	  LEFT JOIN Post_likes as pl ON u.id=pl.user_id
	  LEFT JOIN Post_comments as pc ON u.id=pc.user_id)
      select User_id , username as Username , like_count , comment_count , total_engagement       
      from Total_likes_n_comments ;

#Q12. Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.
WITH hashtag_likes AS (
    SELECT pt.tag_id, AVG(likes) AS avg_likes
    FROM photo_tags pt
    JOIN (
        SELECT p.id AS photo_id, COUNT(l.user_id) AS likes
        FROM photos p
        LEFT JOIN likes l ON p.id = l.photo_id
        GROUP BY p.id
    ) AS photo_likes ON pt.photo_id = photo_likes.photo_id
    GROUP BY pt.tag_id
)
SELECT t.tag_name, hl.avg_likes
FROM hashtag_likes hl
JOIN tags t ON hl.tag_id = t.id
ORDER BY hl.avg_likes DESC;

#Q13. Retrieve the users who have started following someone after being followed by that person
SELECT f1.follower_id, f1.followee_id
FROM follows f1
JOIN follows f2 ON f1.follower_id = f2.followee_id AND f1.followee_id = f2.follower_id;

## Subjective Question Answer
#Q1 Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?
SELECT users.username, COUNT(likes.user_id) + COUNT(comments.user_id) AS total_engagement
FROM users LEFT JOIN likes ON likes.user_id = users.id LEFT JOIN comments ON comments.user_id = users.id
GROUP BY users.id;


#Q2.For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?
SELECT username FROM  users WHERE  id NOT IN (
SELECT DISTINCT user_id FROM likes WHERE created_at > NOW() - INTERVAL 30 DAY UNION
SELECT DISTINCT user_id FROM comments WHERE created_at > NOW() - INTERVAL 30 DAY);

#Q3. Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?
SELECT tags.tag_name, COUNT(DISTINCT likes.user_id) + COUNT(DISTINCT comments.user_id) AS total_engagement
FROM tags JOIN photo_tags ON photo_tags.tag_id = tags.id
JOIN photos ON photos.id = photo_tags.photo_id
LEFT JOIN likes ON likes.photo_id = photos.id
LEFT JOIN comments ON comments.photo_id = photos.id
GROUP BY 
    tags.tag_name
ORDER BY 
    total_engagement DESC;

#Q4. Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?
With Likes as 
(SELECT photo_id, COUNT(*) AS Total_likes 
FROM likes GROUP BY photo_id) , 

Comments as 
(SELECT photo_id, COUNT(*) AS Total_comments 
FROM comments GROUP BY photo_id) 

 SELECT
    DATE_FORMAT(p.created_dat, '%H') AS Hour_of_day,
    DAYNAME(p.created_dat) AS Day_of_week,
    COUNT(p.id) AS Total_posts,
    COALESCE(SUM(L.Total_likes), 0) AS Total_likes,
    COALESCE(SUM(c.Total_comments), 0) AS Total_comments,
    ROUND((COALESCE(SUM(l.Total_likes), 0) + COALESCE(SUM(c.Total_comments), 0)) / COUNT(p.id),0) 
    AS Average_engagement
FROM photos AS p
LEFT JOIN Likes as l
ON p.id = l.photo_id
LEFT JOIN Comments as c 
ON p.id = c.photo_id
GROUP BY Hour_of_day,Day_of_week ;


#Q5. Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?
WITH Followers AS (
    SELECT f.follower_id AS user_id,
          COUNT(f.follower_id) AS follower_count
    FROM follows f
    GROUP BY f.follower_id),
total_likes_n_comments AS (
    SELECT p.user_id,
        COUNT(DISTINCT l.user_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id),
Final AS (
    SELECT u.id, u.username as Username,
	coalesce(sum(f.follower_count),0) as Follower_count,
	coalesce(sum(t.total_likes),0) AS Total_likes,
	coalesce(sum(t.total_comments),0) AS Total_comments,
	Round(coalesce(sum(t.total_likes), 0) + coalesce(sum(t.total_comments),0) / coalesce(count(f.follower_count),1),0) 
	AS Engagement_rate
    FROM users u
    LEFT JOIN Followers f ON u.id = f.user_id
    LEFT JOIN total_likes_n_comments t ON u.id = t.user_id
    group by u.id ,u.username )
    
SELECT
    id AS User_id, Username, Follower_count, 
    Total_likes, Total_comments, Engagement_rate
FROM Final 
where Follower_count != 0
ORDER BY engagement_rate DESC, follower_count DESC
limit 10;

 #Q6. Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?
With Likes as 
 (SELECT user_id, COUNT(*) AS likes_count 
 FROM likes 
 GROUP BY user_id),
 
Comments as 
 (SELECT user_id, COUNT(*) AS comments_count 
 FROM comments 
 GROUP BY user_id) 
 
 SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(SUM(likes_count), 0) AS Total_likes,
    COALESCE(SUM(comments_count), 0) AS Total_comments,
    COALESCE(COUNT(DISTINCT p.id), 0) AS Total_photos,
    CASE 
        WHEN COALESCE(COUNT(DISTINCT p.id), 0) = 0 THEN 0 
        ELSE (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) 
    END AS Engagement_rate,
    CASE 
        WHEN COALESCE(COUNT(DISTINCT p.id), 0) = 0 THEN 'Inactive Users'
        WHEN (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) > 150 THEN 'Ative Users'
        WHEN (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) BETWEEN 100 AND 150 
        THEN 'Moderately Active Users'
        ELSE 'Inactive Users'
    END AS Engagement_level
FROM users as u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN Likes as l 
ON u.id = l.user_id
LEFT JOIN Comments as c
ON u.id = c.user_id
GROUP BY u.id, u.username
ORDER BY engagement_rate DESC;

#Q8. How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events?
SELECT 
    users.username, 
    COUNT(photos.id) AS post_count, 
    COUNT(likes.user_id) + COUNT(comments.user_id) AS total_engagement
FROM 
    users
LEFT JOIN photos ON photos.user_id = users.id
LEFT JOIN likes ON likes.photo_id = photos.id
LEFT JOIN comments ON comments.photo_id = photos.id
GROUP BY 
    users.id
ORDER BY 
    total_engagement DESC, post_count DESC;

