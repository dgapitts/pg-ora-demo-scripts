DROP TABLE IF EXISTS DOCTORS CASCADE;
DROP TABLE IF EXISTS SCHEDULES CASCADE;


CREATE TABLE doctors (
    id INT PRIMARY KEY,
    name TEXT
);

CREATE TABLE schedules (
    day DATE,
    doctor_id INT REFERENCES doctors (id),
    on_call BOOL,
    PRIMARY KEY (day, doctor_id)
);

INSERT INTO doctors VALUES
    (1, 'Abe'),
    (2, 'Betty');

INSERT INTO schedules VALUES
    ('2018-10-01', 1, true),
    ('2018-10-01', 2, true),
    ('2018-10-02', 1, true),
    ('2018-10-02', 2, true),
    ('2018-10-03', 1, true),
    ('2018-10-03', 2, true),
    ('2018-10-04', 1, true),
    ('2018-10-04', 2, true),
    ('2018-10-05', 1, true),
    ('2018-10-05', 2, true),
    ('2018-10-06', 1, true),
    ('2018-10-06', 2, true),
    ('2018-10-07', 1, true),
    ('2018-10-07', 2, true);

