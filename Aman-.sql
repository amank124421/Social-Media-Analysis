USE ig_clone;

select * from users;
select * from photos;
select * from photo_tags;
select * from follows;
select * from comments;
select * from likes;
select * from tags;

#Objective_Answer_1
select count(*) from users
where id is NULL or username is NULL or created_at is NULL;

select count(distinct id), count(distinct username), count(distinct created_at) from users;

select count(*) from photos
where id is NULL or image_url is NULL or user_id is NULL or created_dat is NULL;

select count(distinct id), count(distinct image_url), count(distinct user_id), count(distinct created_dat) from photos;

select count(*) from photo_tags
where photo_id is NULL or tag_id is NULL;

select count(distinct photo_id), count(distinct tag_id) from photo_tags;

select count(*) from follows
where follower_id is NULL or followee_id is NULL or created_at is NULL;

select count(*) from comments
where id is NULL or comment_text is NULL or user_id is NULL or photo_id is NULL or created_at is NULL;

select count(*) from likes
where user_id is NULL or photo_id is NULL or created_at is NULL;

select count(distinct user_id), count(distinct photo_id), count(distinct created_at) from likes;

select count(*) from tags
where id is NULL or tag_name is NULL or created_at is NULL;

select count(distinct id), count(distinct tag_name), count(distinct created_at) from tags;

#Objective_Answer_2
select count(*) from users;
select count(*) from photos;
select count(*) from likes;
select count(*) from tags;
select count(*) from photo_tags;
select count(*) from follows;
select count(*) from comments;

#Objective_Answer_3
select round(count(tag_id) / count(distinct photo_id), 4) as avg_no_of_tags 
from photo_tags;

#Objective_Answer_4
WITH post_likes AS (
    SELECT photo_id, COUNT(DISTINCT user_id) AS like_count FROM likes GROUP BY photo_id
),
post_comments AS (
    SELECT photo_id, COUNT(DISTINCT user_id) AS comment_count FROM comments GROUP BY photo_id
),
user_followers AS (
    SELECT followee_id, COUNT(DISTINCT follower_id) AS follower_count FROM follows GROUP BY followee_id
)
SELECT u.id, u.username, 
       ROUND(COALESCE(SUM(COALESCE(pl.like_count, 0) + COALESCE(pc.comment_count, 0)) / MAX(uf.follower_count) * 100, 0), 2) AS "engagement_rate (%)"
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN post_likes pl ON p.id = pl.photo_id
LEFT JOIN post_comments pc ON p.id = pc.photo_id
LEFT JOIN user_followers uf ON u.id = uf.followee_id
GROUP BY u.id, u.username
ORDER BY 3 DESC LIMIT 10;

#Objective_Answer_5

#Highest_Followers
SELECT u.username, COUNT(DISTINCT f.follower_id) AS follower_count
FROM follows f
JOIN users u ON u.id = f.followee_id
GROUP BY u.id, u.username
ORDER BY follower_count DESC LIMIT 1;

#Highest_Followings
SELECT u.username, COUNT(DISTINCT f.followee_id) AS following_count
FROM follows f
JOIN users u ON u.id = f.follower_id
GROUP BY u.id, u.username
ORDER BY following_count DESC LIMIT 1;

#Objective_Answer_6
WITH post_stats AS (
    SELECT p.user_id, p.id AS photo_id,
           (SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id) AS like_count,
           (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id) AS comment_count
    FROM photos p
)
SELECT u.username,
       ROUND(AVG(ps.like_count + ps.comment_count), 2) AS avg_engagement_per_post
FROM users u
JOIN post_stats ps ON u.id = ps.user_id
GROUP BY u.id, u.username
ORDER BY avg_engagement_per_post DESC;

#Objective_Answer_7
SELECT u.id, u.username 
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

#Objective_Answer_8A
SELECT u.id, u.username
FROM users u
JOIN likes l ON u.id = l.user_id
GROUP BY u.id, u.username
HAVING COUNT(DISTINCT l.photo_id) = (SELECT COUNT(DISTINCT id) FROM photos);

#Objective_Answer_8B
SELECT u.id, u.username
FROM users u
LEFT JOIN comments c ON u.id = c.user_id
WHERE c.id IS NULL;

#Objective_Answer_10
WITH photo_metrics AS (
    SELECT p.user_id,
           (SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id) AS likes_c,
           (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id) AS comments_c,
           (SELECT COUNT(*) FROM photo_tags pt WHERE pt.photo_id = p.id) AS tags_c
    FROM photos p
)
SELECT u.id, u.username, 
       COALESCE(SUM(pm.likes_c), 0) AS like_count, 
       COALESCE(SUM(pm.comments_c), 0) AS comment_count, 
       COALESCE(SUM(pm.tags_c), 0) AS tag_count 
FROM users u
LEFT JOIN photo_metrics pm ON u.id = pm.user_id
GROUP BY u.id, u.username
ORDER BY u.id;

#Objective_Answer_11
WITH recent_likes AS (
    SELECT photo_id, COUNT(*) AS like_count 
    FROM likes 
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) 
    GROUP BY photo_id
),
recent_comments AS (
    SELECT photo_id, COUNT(*) AS comment_count 
    FROM comments 
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH) 
    GROUP BY photo_id)
SELECT u.id, u.username, 
       COALESCE(SUM(COALESCE(rl.like_count, 0) + COALESCE(rc.comment_count, 0)), 0) AS total_engagement,
       DENSE_RANK() OVER(ORDER BY COALESCE(SUM(COALESCE(rl.like_count, 0) + COALESCE(rc.comment_count, 0)), 0) DESC) AS `rank`
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN recent_likes rl ON p.id = rl.photo_id
LEFT JOIN recent_comments rc ON p.id = rc.photo_id
GROUP BY u.id, u.username
ORDER BY total_engagement DESC;

#Objective_Answer_12
SELECT t.tag_name AS hashtag, 
       ROUND(COUNT(l.user_id) / COUNT(DISTINCT pt.photo_id), 2) AS avg_likes
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
LEFT JOIN likes l ON pt.photo_id = l.photo_id
GROUP BY t.id, t.tag_name
ORDER BY avg_likes DESC
LIMIT 1;

#Objective_Answer_13
SELECT u2.username AS user, u1.username AS followed_by 
FROM follows f1
JOIN follows f2 ON f1.follower_id = f2.followee_id 
               AND f1.followee_id = f2.follower_id 
               AND f2.created_at >= f1.created_at
JOIN users u1 ON f1.follower_id = u1.id
JOIN users u2 ON f1.followee_id = u2.id;

----------------------------------------------------------------------------------------------------------------------------

#Subjective_Answer_1
WITH user_engagements AS (
    SELECT p.user_id, COUNT(DISTINCT p.id) AS Total_Posts,
           SUM((SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id)) AS total_likes,
           SUM((SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id)) AS total_comments
    FROM photos p
    GROUP BY p.user_id
),
follower_counts AS (
    SELECT followee_id, COUNT(*) AS follower_count FROM follows GROUP BY followee_id
)
SELECT u.id, u.username, 
       COALESCE(ue.Total_Posts, 0) AS Total_Posts, 
       ROUND(COALESCE((ue.total_likes + ue.total_comments) / fc.follower_count * 100, 0), 2) AS "engagement_rate (%)"
FROM users u
JOIN follower_counts fc ON u.id = fc.followee_id
LEFT JOIN user_engagements ue ON u.id = ue.user_id
GROUP BY u.id, u.username, ue.Total_Posts, ue.total_likes, ue.total_comments, fc.follower_count
ORDER BY Total_Posts DESC, 4 DESC LIMIT 10;

#Subjective_Answer_2
SELECT id, username, 0 AS Total_Posts, 0 AS no_of_likes, 0 AS no_of_comments
FROM users
WHERE id NOT IN (SELECT user_id FROM photos)
  AND id NOT IN (SELECT user_id FROM likes)
  AND id NOT IN (SELECT user_id FROM comments);

#Subjective_Answer_3
WITH tag_stats AS (
    SELECT pt.tag_id,
           COUNT(DISTINCT pt.photo_id) AS posts_using_hashtag,
           SUM((SELECT COUNT(*) FROM likes l WHERE l.photo_id = pt.photo_id)) AS total_likes,
           SUM((SELECT COUNT(*) FROM comments c WHERE c.photo_id = pt.photo_id)) AS total_comments
    FROM photo_tags pt
    GROUP BY pt.tag_id
)
SELECT t.id, t.tag_name,
       ROUND((ts.total_likes + ts.total_comments) / ts.posts_using_hashtag, 2) AS engagement_rate
FROM tags t
JOIN tag_stats ts ON t.id = ts.tag_id
ORDER BY engagement_rate DESC LIMIT 5;

#Subjective_Answer_4

#Part_1(Peak_Posting_Hour)
SELECT HOUR(created_dat) AS "post_hour", COUNT(*) AS total_posts
FROM photos
GROUP BY 1 ORDER BY total_posts DESC;

#Part_2(Peak_engagement_Hour)
WITH engagement_data AS (
    SELECT DATE(p.created_dat) AS post_date, HOUR(p.created_dat) AS engagement_hour, p.id AS photo_id,
           (SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id) AS like_count,
           (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id) AS comment_count
    FROM photos p
)
SELECT post_date, engagement_hour, 
       COUNT(photo_id) AS total_posts, 
       SUM(like_count) AS total_likes, 
       SUM(comment_count) AS total_comments, 
       SUM(like_count + comment_count) AS total_engagement
FROM engagement_data
GROUP BY post_date, engagement_hour
ORDER BY post_date DESC, engagement_hour DESC;

#Subjective_Answer_5
WITH follower_base AS (
    SELECT followee_id AS user_id, COUNT(*) AS follower_count FROM follows GROUP BY followee_id
),
engagement_metrics AS (
    SELECT p.user_id,
           SUM((SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id)) AS total_likes,
           SUM((SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id)) AS total_comments
    FROM photos p
    GROUP BY p.user_id
)
SELECT u.id, u.username, fb.follower_count, 
       ROUND(COALESCE(((em.total_likes + em.total_comments) / fb.follower_count) * 100, 0), 2) AS "engagement_rate (%)"
FROM users u
JOIN follower_base fb ON u.id = fb.user_id
LEFT JOIN engagement_metrics em ON u.id = em.user_id
ORDER BY follower_count DESC, 4 DESC LIMIT 10;

#Subjective_Answer_7
CREATE TABLE IF NOT EXISTS ad_campaigns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_name VARCHAR(255) NOT NULL,
    impressions INT,
    clicks INT,
    conversions INT,
    cost DECIMAL(10,2),
    revenue DECIMAL(10,2),
    campaign_date DATE
);

INSERT IGNORE INTO ad_campaigns (id, campaign_name, impressions, clicks, conversions, cost, revenue, campaign_date) 
VALUES 
(1, 'incre_1', 1000, 200, 10, 1000, 1500, curdate()), 
(2, 'incre_2', 2000, 700, 50, 1500, 2800, curdate()), 
(3, 'incre_3', 2500, 450, 45, 2000, 2500, curdate());

SELECT id, campaign_name, impressions, clicks, conversions, 
       cost AS "cost($)", revenue AS "revenue($)", 
       CASE WHEN impressions > 0 THEN ROUND((clicks/impressions)*100, 2) ELSE 0 END AS click_through_rate, 
       CASE WHEN clicks > 0 THEN ROUND((conversions/clicks)*100, 2) ELSE 0 END AS conversion_rate, 
       CASE WHEN conversions > 0 THEN ROUND((cost/conversions), 2) ELSE 0 END AS cost_per_acquisition, 
       CASE WHEN cost > 0 THEN ROUND((revenue/cost), 2) ELSE 0 END AS return_on_ad_spend
FROM ad_campaigns;

#Subjective_Answer_8
WITH user_metrics AS (
    SELECT p.user_id, COUNT(DISTINCT p.id) AS post_count,
           SUM((SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id)) / COUNT(DISTINCT p.id) AS avg_like_count,
           SUM((SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id)) / COUNT(DISTINCT p.id) AS avg_comment_count
    FROM photos p
    GROUP BY p.user_id
),
follower_stats AS (
    SELECT followee_id AS user_id, COUNT(*) AS follower_count FROM follows GROUP BY followee_id
)
SELECT u.id AS user_id, u.username, fs.follower_count, um.post_count, 
       ROUND(um.avg_like_count, 2) AS avg_like_count, 
       ROUND(um.avg_comment_count, 2) AS avg_comment_count
FROM users u
JOIN follower_stats fs ON u.id = fs.user_id
JOIN user_metrics um ON u.id = um.user_id
ORDER BY fs.follower_count DESC, um.avg_like_count DESC, um.avg_comment_count DESC, um.post_count DESC LIMIT 10;

#Subjective_Answer_10
UPDATE user_interactions
SET engagement_type = 'Heart'
WHERE engagement_type = 'Like';