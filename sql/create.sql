drop table if exists vote;

--
-- Create table `vote`
--
CREATE TABLE vote (
  name varchar(255),
  value integer
);

-- 
-- Insert values into `vote`
--
INSERT INTO vote VALUES
('up', '0'),
('down', '0');
