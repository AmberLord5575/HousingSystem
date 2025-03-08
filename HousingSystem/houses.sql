CREATE TABLE IF NOT EXISTS houses (
    postal VARCHAR(255) PRIMARY KEY,
    owner VARCHAR(255),
    purchasedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS house_owners (
    postal VARCHAR(255),
    owner_cfxname VARCHAR(255),
    PRIMARY KEY (postal, owner_cfxname)
);

CREATE TABLE IF NOT EXISTS house_keys (
    postal VARCHAR(255),
    owner VARCHAR(255),
    PRIMARY KEY (postal, owner)
);
