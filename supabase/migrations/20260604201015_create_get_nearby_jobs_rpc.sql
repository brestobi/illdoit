-- Create a function to find nearby jobs
CREATE OR REPLACE FUNCTION public.get_nearby_jobs(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION
)
RETURNS SETOF public.jobs
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.jobs
  WHERE status = 'open'
  AND (6371 * acos(
    cos(radians(user_lat)) * cos(radians(latitude)) *
    cos(radians(longitude) - radians(user_lng)) +
    sin(radians(user_lat)) * sin(radians(latitude))
  )) <= radius_km
  ORDER BY (6371 * acos(
    cos(radians(user_lat)) * cos(radians(latitude)) *
    cos(radians(longitude) - radians(user_lng)) +
    sin(radians(user_lat)) * sin(radians(latitude))
  ));
$$;
