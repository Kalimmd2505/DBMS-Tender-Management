ALTER TABLE contract
ADD COLUMN Awarded_By_UID INT,
ADD CONSTRAINT fk_awarded_by
    FOREIGN KEY (Awarded_By_UID) REFERENCES user(User_ID);