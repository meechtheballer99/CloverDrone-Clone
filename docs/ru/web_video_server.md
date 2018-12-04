# Просмотр изображений с камер

Для просмотра изображений с камер можно воспользовться [rviz](rviz.md), rqt, или смотреть их через браузер, используя web\_video\_server.

См. подробнее про [использование rqt](rviz.md).

## Просмотр через браузер

### Настройка

Необходимо убедиться, что в launch-файле Клевера \(`~/catkin_ws/src/clever/clever/launch/clever.launch`\) включен запуск `web_video_server`:

```xml
<arg name="web_video_server" default="true"/>
```

При изменении launch-файла необходимо перезапустить пакет `clever`:

```bash
sudo systemctl restart clever
```

### Просмотр

Для просмотра видеострима нужно [подключиться к Wi-Fi](wifi.md) Клевера \(`CLEVER-xxxx`\), перейти на страницу [http://192.168.11.1:8080/](http://192.168.11.1:8080/) и выбрать топик камеры.

![Просмотр web_video_server](../assets/web_video_server.png)

Если передача картинки работает слишком медленно, можно ускорить ее, меняя GET-параметр `quality` (от 1 до 100), который отвечает за сжатие видеострима, например:

http://192.168.11.1:8080/stream_viewer?topic=/main_camera/image_raw&quality=1

По URL выше будет доступен стрим с основной камеры в минимальном возможном качестве.

Также доступны параметры `width`, `height` и другие. Подробнее о `web_video_server`: http://wiki.ros.org/web_video_server.