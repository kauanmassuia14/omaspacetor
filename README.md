# OmaSpaceTor

Um widget para a barra do Omarchy que mostra os workspaces agrupados por monitor. Cada tela tem seus próprios números de 1 a 10: você pode usar, por exemplo, o workspace 1 no notebook e outro workspace 1 no monitor externo.

No Hyprland, workspaces numéricos como `1` e `2` são globais. Por isso, `Super+1` pode levar você a uma tela diferente da que está usando. O OmaSpaceTor mantém esses workspaces existentes e cria um workspace local nomeado quando o mesmo número já está em outro monitor.

## O que aparece na barra

- Um grupo de números para cada monitor conectado.
- O monitor com foco do teclado fica destacado.
- O workspace aberto em cada monitor também fica destacado.
- Workspaces vazios são criados ao clicar neles.
- O grupo usa o nome real da saída no tooltip. Saídas `eDP`, `LVDS` e `DSI` são identificadas como “Laptop” por padrão.

O widget é colocado à esquerda por padrão. Clique em um número para abrir esse workspace naquele monitor. O workspace 10 aparece como `0`, igual ao atalho padrão do Omarchy.

## Instalação

Depois de enviar este repositório ao GitHub:

```sh
omarchy plugin add git@github.com:kauanmassuia14/omaspacetor.git --enable
```

Escolha `left` se o instalador perguntar a seção. Para mudar a posição depois:

```sh
omarchy plugin enable kauanmassuia14.omaspacetor left
omarchy plugin disable omarchy.workspaces
```

Desativar `omarchy.workspaces` remove o seletor numérico antigo para não duplicar os números na barra.

## Usar Super + número no monitor em foco

O widget funciona com cliques sem alterar os atalhos existentes. Para fazer `Super+1` até `Super+0` selecionar o número no monitor em foco, inclua a integração opcional em `~/.config/hypr/bindings.lua`, depois de instalar o plugin:

```lua
dofile((os.getenv("HOME") or "") .. "/.config/omarchy/plugins/kauanmassuia14.omaspacetor/hyprland-bindings.lua")
```

Essa integração substitui apenas `Super+1` até `Super+0`. Os atalhos `Super+Shift+número` para mover uma janela continuam como estão. Workspaces numéricos que já existem são reaproveitados no monitor onde estão; se o número estiver em outro monitor, o atalho abre um workspace local separado.

Se houver um erro ao carregar o arquivo Lua, remova a linha `dofile` de `bindings.lua` para voltar imediatamente aos atalhos padrão.

## Rótulos de monitor

Para usar rótulos curtos na barra, defina `monitorLabels` na configuração do widget. Exemplo:

```json
{
  "monitorLabels": "{\"eDP-1\":\"NB\",\"DP-1\":\"EXT\"}"
}
```

Os nomes das saídas podem ser consultados com `hyprctl monitors`.

## Remover

```sh
omarchy plugin remove kauanmassuia14.omaspacetor
```

Se você ativou a integração de teclado, remova também a linha `dofile` de `~/.config/hypr/bindings.lua`. Em seguida, reative `omarchy.workspaces` se quiser voltar ao widget original.

## Como o atalho escolhe um workspace

Quando o número já pertence a um workspace numérico no monitor em foco, o atalho continua usando esse workspace. Caso contrário, ele escolhe um workspace com nome próprio para aquele monitor e número. Assim, o notebook pode ter seu workspace 1 e o monitor externo outro workspace 1, enquanto a barra deixa claro em qual tela você está.
