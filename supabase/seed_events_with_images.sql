-- Images de couverture pour les événements de test (URLs publiques Unsplash)
-- À exécuter dans SQL Editor après avoir inséré les événements

UPDATE events SET cover_image_url = 'https://images.unsplash.com/photo-1459749411175-047fc950c9c0?w=800&q=80'
WHERE title ILIKE '%Festival%' OR title ILIKE '%Xalam%';

UPDATE events SET cover_image_url = 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&q=80'
WHERE title ILIKE '%Concert%' OR title ILIKE '%Youssou%';

UPDATE events SET cover_image_url = 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80'
WHERE title ILIKE '%Tech%' OR title ILIKE '%Conférence%' OR title ILIKE '%Summit%';

UPDATE events SET cover_image_url = 'https://images.unsplash.com/photo-1461896836934-ffe607ba6851?w=800&q=80'
WHERE title ILIKE '%Coupe%' OR title ILIKE '%Sport%' OR title ILIKE '%Finale%';

UPDATE events SET cover_image_url = 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80'
WHERE title ILIKE '%Jazz%' OR cover_image_url IS NULL;

-- Vérification
SELECT title, cover_image_url IS NOT NULL AS has_image FROM events ORDER BY start_at;
