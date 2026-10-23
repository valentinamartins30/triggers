exercicio 1:
CREATE TABLE estoque (
    id SERIAL PRIMARY KEY,
    nome_item VARCHAR(100) NOT NULL,
    quantidade INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION fn_valida_estoque_minimo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantidade < 0 THEN
        RAISE EXCEPTION 'Operação cancelada! O item "%" não pode ter estoque negativo (Tentativa: % unidade(s)).', 
            NEW.nome_item, NEW.quantidade;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_estoque
BEFORE INSERT OR UPDATE ON estoque
FOR EACH ROW
EXECUTE FUNCTION fn_valida_estoque_minimo();

exercicio 2:
create table contas (
	id serial primary key,
	cliente varchar(150) not null,
	saldo numeric(10, 2) not null default 0.00
	);

CREATE TABLE movimentacoes (
    id SERIAL PRIMARY KEY,
    conta_id INT REFERENCES contas(id),
    tipo VARCHAR(1) CHECK (tipo IN ('C', 'D')),
    valor NUMERIC(10, 2) NOT NULL,
);

CREATE OR REPLACE FUNCTION fn_atualiza_saldo_conta()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tipo = 'C' THEN
        UPDATE contas SET saldo = saldo + NEW.valor WHERE id = NEW.conta_id;
    ELSIF NEW.tipo = 'D' THEN
        UPDATE contas SET saldo = saldo - NEW.valor WHERE id = NEW.conta_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualiza_saldo
AFTER INSERT ON movimentacoes
FOR EACH ROW
EXECUTE FUNCTION fn_atualiza_saldo_conta();

exercicio 3:
CREATE TABLE funcionarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    salario NUMERIC(10, 2) NOT NULL
);

CREATE TABLE historico_carreira (
    id SERIAL PRIMARY KEY,
    funcionario_id INT NOT NULL,
    cargo_antigo VARCHAR(50),
    cargo_novo VARCHAR(50),
    salario_antigo NUMERIC(10, 2),
    salario_novo NUMERIC(10, 2),
    data_alteracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_log_alteracao_carreira()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.cargo IS DISTINCT FROM NEW.cargo OR OLD.salario IS DISTINCT FROM NEW.salario THEN
        INSERT INTO historico_carreira (funcionario_id, cargo_antigo, cargo_novo, salario_antigo, salario_novo)
        VALUES (OLD.id, OLD.cargo, NEW.cargo, OLD.salario, NEW.salario);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_carreira
AFTER UPDATE ON funcionarios
FOR EACH ROW
EXECUTE FUNCTION fn_log_alteracao_carreira();

INSERT INTO FUNCIONARIOS (nome, cargo, salario) VALUES
('Maria Santos', 'Desenvolvedora Jr', 3500.00);

UPDATE funcionarios SET cargo = 'Desenvolvedora Pleno', salario = 5500.00 WHERE id = 1;

exercicio 4:
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE clientes_deletados_log (
    id SERIAL PRIMARY KEY,
    cliente_id INT,
    nome VARCHAR(100),
    email VARCHAR(100),
    data_remocao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_soft_delete_cliente()
RETURNS TRIGGER AS $$
BEGIN
 
    INSERT INTO clientes_deletados_log (cliente_id, nome, email)
    VALUES (OLD.id, OLD.nome, OLD.email);


    UPDATE clientes SET ativo = FALSE WHERE id = OLD.id;


    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_soft_delete_cliente
BEFORE DELETE ON clientes
FOR EACH ROW
EXECUTE FUNCTION fn_soft_delete_cliente();

INSERT INTO clientes (nome, email) VALUES ('Arthur Melzi', 'carlos@email.com');
DELETE FROM clientes WHERE id = 1;

exercicio 5: 
CREATE TABLE reservas (
    id SERIAL PRIMARY KEY,
    numero_quarto INT NOT NULL,
    data_checkin DATE NOT NULL,
    data_checkout DATE NOT NULL,
    valor_diaria NUMERIC(10, 2) NOT NULL,
    valor_total NUMERIC(10, 2)
);

CREATE OR REPLACE FUNCTION fn_processa_reserva()
RETURNS TRIGGER AS $$
DECLARE
    dias_estadia INT;
BEGIN
    
    IF NEW.data_checkout <= NEW.data_checkin THEN
        RAISE EXCEPTION 'A data de check-out (%) precisa ser posterior à data de check-in (%)!', 
            NEW.data_checkout, NEW.data_checkin;
    END IF;

   
    dias_estadia := NEW.data_checkout - NEW.data_checkin;

 
    NEW.valor_total := dias_estadia * NEW.valor_diaria;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_processa_reserva
BEFORE INSERT OR UPDATE ON reservas
FOR EACH ROW
EXECUTE FUNCTION fn_processa_reserva();

INSERT INTO reservas (numero_quarto, data_checkin, data_checkout, valor_diaria)
VALUES (101, '2026-11-10', '2026-11-05', 200.00);

INSERT INTO reservas (numero_quarto, data_checkin, data_checkout, valor_diaria)
VALUES (101, '2026-11-01', '2026-11-06', 200.00);

