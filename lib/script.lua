-- IDEA: if there is no key, creates one with count = 1, time = now() and expire the key 
-- after window (default should be 60s).
-- If number of messages is greater than count_limit, sets time = now() and creates a backoff time,
-- and expire the key after backoff + window.
-- If now > time + backoff, sets count to zero

local key = KEYS[1]
local now = ARGV[1]
local count_limit = ARGV[2]
local window = ARGV[3]

if redis.call("EXISTS", key) == 0 then
  redis.call("HMSET", key, "time", now, "count", 1)
  redis.call("EXPIRE", key, window)
  return "allow"
end

local count = redis.call("HINCRBY", key, "count", 1)
if count < count_limit then
  return "allow"
end

local params =  redis.call("HMGET", key, "time", "count", "backoff")
local backoff = params["backoff"]
if backoff == 0 then
  redis.call("HMSET", key, "time", now, "backoff", window)
  redis.call("EXPIRE", key, 2 * window)
  return "deny"
end

if now < params["time"] + params["backoff"] then
  return "deny"
end

redis.call("HSET", key, "count", 1)

return "allow"
