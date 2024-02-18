-- Criação de uma tabela
CREATE TABLE exemplo_tabela (
    id INT PRIMARY KEY,
    nome VARCHAR(50),
    idade INT
);

-- Criação de uma sequência
CREATE SEQUENCE exemplo_sequencia
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 10;
/
-- Criação de um índice na tabela
CREATE INDEX idx_nome ON exemplo_tabela(nome);

-- Concessão de permissões
GRANT SELECT, INSERT, UPDATE, DELETE ON exemplo_tabela TO usuario_exemplo;

