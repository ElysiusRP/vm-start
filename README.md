# vm-start

Container FiveM (Alpine) com auto-update via git. Variáveis de ambiente: veja `.env.example`.

## Deploy no Coolify (Docker Compose)

Use o build pack **Docker Compose** apontando para `/docker-compose.yaml`.
Não use o build pack Dockerfile: o Coolify não publica a mesma porta em TCP e UDP
(o campo de portas rejeita duplicadas e o `--publish` em opções customizadas é ignorado),
e o FiveM precisa de **30120 em TCP e UDP**.

O `docker-compose.yaml` já resolve dois problemas:

1. **UDP**: publica `30120/tcp`, `30120/udp` e `40120/tcp`.
2. **Banco (MariaDB do Coolify)**: apps em Compose ganham uma rede própria e não enxergam
   o banco (`getaddrinfo EAI_AGAIN <uuid-do-banco>`). O serviço está ligado à rede externa
   `coolify`, a mesma do banco.

### Passo a passo
1. Cadastre as variáveis do `.env.example` na aplicação (inclusive `TXHOST_DEFAULT_*`).
   `TXHOST_DEFAULT_DBHOST` = UUID/nome do container do MariaDB.
2. Volume persistente: o compose usa o volume externo `<uuid-da-app>-txdata` montado em `/txData`
   (`FX_DATA_PATH=/txData`). Ajuste o `name:` em `volumes` se a aplicação for outra.
3. Deploy. Confira com `docker ps` se aparece `0.0.0.0:30120->30120/udp`.

### Firewall
Libere `30120/tcp`, `30120/udp` e `40120/tcp` no painel do provedor e no `ufw`.

### Teste rápido da UDP (de fora da VPS)
```python
import socket
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.settimeout(5)
s.sendto(b"\xff\xff\xff\xffgetinfo xxx",("IP_DA_VPS",30120))
print(s.recvfrom(2000)[0])   # deve vir "infoResponse"
```
