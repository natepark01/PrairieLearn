-- BLOCK select_questions_manual_grading
SELECT
    aq.*,
    q.qid,
    q.title,
    q.id AS question_id,
    admin_assessment_question_number(aq.id) as number,
    ag.number AS alternative_group_number,
    (count(*) OVER (PARTITION BY ag.number)) AS alternative_group_size,
    (SELECT COUNT(s.id)
     FROM 
         submissions AS s
     WHERE (s.auth_user_id, s.date) 
        IN (
             SELECT s.auth_user_id, MAX(s.date)
             FROM
                 submissions AS s
                 JOIN variants AS v ON (s.variant_id = v.id)
                 JOIN instance_questions AS iq ON (v.instance_question_id = iq.id)
             WHERE
                 iq.assessment_question_id = aq.id
             GROUP BY s.auth_user_id
         )
         AND graded_at IS NULL) AS num_ungraded,
    (SELECT COUNT(s.id)
     FROM 
         submissions AS s
     WHERE (s.auth_user_id, s.date) 
        IN (
             SELECT s.auth_user_id, MAX(s.date)
             FROM
                 submissions AS s
                 JOIN variants AS v ON (s.variant_id = v.id)
                 JOIN instance_questions AS iq ON (v.instance_question_id = iq.id)
             WHERE
                 iq.assessment_question_id = aq.id
             GROUP BY s.auth_user_id
         )
         AND graded_at IS NOT NULL) AS num_graded,
    (SELECT array_agg(DISTINCT u.uid)
     FROM
         instance_questions AS iq
         JOIN users AS u ON (u.user_id = iq.manual_grading_user)
     WHERE
         iq.assessment_question_id = aq.id) AS manual_grading_users
FROM
    assessment_questions AS aq
    JOIN questions AS q ON (q.id = aq.question_id)
    JOIN alternative_groups AS ag ON (ag.id = aq.alternative_group_id)
WHERE
    aq.assessment_id = $assessment_id
    AND aq.deleted_at IS NULL
    AND q.deleted_at IS NULL
ORDER BY aq.number;
