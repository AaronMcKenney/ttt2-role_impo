local L = LANG.GetLanguageTableReference("ru")

-- GENERAL ROLE LANGUAGE STRINGS
L[IMPOSTOR.name] = "Импостор"
L["info_popup_" .. IMPOSTOR.name] = [[Вы импостор! Импосторы - это предатели, имеющие доступ к способности мгновенного убийства с близкого расстояния, способности саботажа и вентиляционным отверстиям, позволяющим им телепортироваться. 

Однако вы не имеете доступа к магазину и в обычном случае наносите небольшой ущерб.]]
L["body_found_" .. IMPOSTOR.abbr] = "Он был импостером!"
L["search_role_" .. IMPOSTOR.abbr] = "Этот человек был импостером"
L["target_" .. IMPOSTOR.name] = "Импостор"
L["ttt2_desc_" .. IMPOSTOR.name] = [[Вы импостор! Импосторы - это предатели, имеющие доступ к способности мгновенного убийства с близкого расстояния, способности саботажа и вентиляционным отверстиям, позволяющим им телепортироваться.

Однако вы не имеете доступа к магазину и в обычном случае наносите небольшой ущерб.]]

-- OTHER ROLE LANGUAGE STRINGS
L["INFORM_ONE_" .. IMPOSTOR.name] = "Обнаружен один импостер среди нас..."
L["INFORM_" .. IMPOSTOR.name] = "Обнаружено {n} импостеров среди нас..."
L["KILL_" .. IMPOSTOR.name] = "УБИТЬ"
L["PRESS_" .. IMPOSTOR.name] = "НАЖМИТЕ "
L["TO_KILL_" .. IMPOSTOR.name] = ", ЧТОБЫ УБИТЬ"

-- VENT LANGUAGE STRINGS
L["VENT_NAME_" .. IMPOSTOR.name] = "Вентиляция"
L["VENT_DESC_" .. IMPOSTOR.name] = [[Вентиляционное отверстие, которое можно разместить вручную на большинстве поверхностей.
Импосторы рассматривают эти вентиляционные трубы как телепортационную сеть.

ПРИМЕЧАНИЕ: По умолчанию вентиляционные отверстия невидимы для не-предателей до тех пор, пока они не войдут или не выйдут из системы.]]
L["VENT_PRIMARY_DESC_" .. IMPOSTOR.name] = "ЛКМ для развёртывания."
L["VENT_CANNOT_PLACE_" .. IMPOSTOR.name] = "Невозможно установить вентиляцию."
L["VENT_MAX_HIT_" .. IMPOSTOR.name] = "Установлено макс. кол-во вентиляционных отверстий."
L["VENT_FULL_" .. IMPOSTOR.name] = "Вы не можете держать больше вентиляций."
L["VENT_CANNOT_TAKE_" .. IMPOSTOR.name] = "Невозможно взять вентиляцию."
L["VENT_TIME_LEFT_" .. IMPOSTOR.name] = "{t} сек. до тех пор, пока вы больше не сможете пользоваться вентиляцией."
L["VENT_TIME_UP_" .. IMPOSTOR.name] = "У вас нет времени, и вы больше не можете пользоваться вентиляцией."
L["VENT_FOREIGNER_ENTER_" .. IMPOSTOR.name] = "Не-предатель в вентиляции!"
L["VENT_FOREIGNER_EXIT_" .. IMPOSTOR.name] = "Не-предатель покинул вентиляцию!"
L["VENT_ANYONE_ENTER_" .. IMPOSTOR.name] = "Кто-то вошёл в вентиляцию."
L["VENT_ANYONE_EXIT_" .. IMPOSTOR.name] = "Кто-то вышел из вентиляции."

-- SABOTAGE LANGUAGE STRINGS
L["SABO_MNGR_" .. IMPOSTOR.name] = "УПРАВЛЕНИЕ СТАНЦИЕЙ"
L["SABO_MNGR_HELP_" .. IMPOSTOR.name] = "Добавьте новую станцию, нажав эту клавишу, глядя на игрока. Выберите существующую точку, нажав эту клавишу, не глядя на игрока."
L["SABO_MNGR_CREATE_PASS_" .. IMPOSTOR.name] = "Создана новая точка создания станции саботажа импостора."
L["SABO_MNGR_BAD_PLY_" .. IMPOSTOR.name] = "Невозможно создать точку создания станции из целевого игрока."
L["SABO_MNGR_TOO_CLOSE_" .. IMPOSTOR.name] = "Целевой игрок находится слишком близко к существующей точке создания станции."
L["SABO_MNGR_UNSAFE_" .. IMPOSTOR.name] = "Не удалось создать точку создания станции от целевого игрока (небезопасное положение)."
L["SABO_CANNOT_REUSE_" .. IMPOSTOR.name] = "Невозможно повторно использовать выбранную точку создания станции. Используйте управление станций, чтобы создать/выбрать другую."
L["SABO_CANNOT_PLACE_" .. IMPOSTOR.name] = "Не удалось создать станцию саботажа импостора!"
L["SABO_LIGHTS_" .. IMPOSTOR.name] = "САБОТИРОВАТЬ СВЕТ"
L["SABO_LIGHTS_INFO_FADE_" .. IMPOSTOR.name] = "Импостер саботировал освещение! У жертв будут происходить перепады напряжения, пока саботаж не закончится!" 
L["SABO_LIGHTS_INFO_MAP_" .. IMPOSTOR.name] = "Импостер саботировал освещение! Жертвы будут в темноте, пока саботаж не закончится!"
L["SABO_LIGHTS_START_" .. IMPOSTOR.name] = "Импостер саботировал свет!"
L["SABO_LIGHTS_END_" .. IMPOSTOR.name] = "Свет снова включился!"
L["SABO_COMMS_" .. IMPOSTOR.name] = "САБОТИРОВАТЬ СВЯЗЬ"
L["SABO_COMMS_INFO_MUTE_AND_DEAF_" .. IMPOSTOR.name] = "Импостер саботировал связь! Жертвы заглушены и не могут ничего говорить до окончания саботажа!"
L["SABO_COMMS_INFO_MUTE_" .. IMPOSTOR.name] = "Импостер саботировал связь! Жертвы заглушены до окончания саботажа!"
L["SABO_COMMS_START_" .. IMPOSTOR.name] = "Импостер саботировал коммуникационный модуль!"
L["SABO_COMMS_END_" .. IMPOSTOR.name] = "Коммуникационный модуль снова включен!"
L["SABO_O2_" .. IMPOSTOR.name] = "САБОТИРОВАТЬ КИСЛОРОД"
L["SABO_O2_INFO_" .. IMPOSTOR.name] = "Импостер совершил саботаж воздухоочистки! Жертвы будут получать постоянный урон, пока диверсия не закончится!"
L["SABO_O2_START_" .. IMPOSTOR.name] = "Импостер саботировал воздух!"
L["SABO_O2_END_" .. IMPOSTOR.name] = "Уровень кислорода вернулся в норму!"
L["SABO_REACT_" .. IMPOSTOR.name] = "САБОТИРОВАТЬ РЕАКТОР"
L["SABO_REACT_INFO_LOSE_" .. IMPOSTOR.name] = "Импостер саботировал реактор! Прекратите саботаж или ПРОИГРАЮТ ВСЕ!"
L["SABO_REACT_INFO_TEAM_WIN_" .. IMPOSTOR.name] = "Импостер саботировал реактор! Прекратите саботаж или КОМАНДА ИМПОСТЕРОВ ПОБЕДИТ!"
L["SABO_REACT_START_" .. IMPOSTOR.name] = "Импостер саботировал реактор!"
L["SABO_REACT_TIME_LEFT_" .. IMPOSTOR.name] = "{t} сек. до расплавления реактора!"
L["SABO_REACT_TEN_" .. IMPOSTOR.name] = "ДЕСЯТЬ"
L["SABO_REACT_NINE_" .. IMPOSTOR.name] = "ДЕВЯТЬ"
L["SABO_REACT_EIGHT_" .. IMPOSTOR.name] = "ВОСЕМЬ"
L["SABO_REACT_SEVEN_" .. IMPOSTOR.name] = "СЕМЬ"
L["SABO_REACT_SIX_" .. IMPOSTOR.name] = "ШЕСТЬ"
L["SABO_REACT_FIVE_" .. IMPOSTOR.name] = "ПЯТЬ"
L["SABO_REACT_FOUR_" .. IMPOSTOR.name] = "ЧЕТЫРЕ"
L["SABO_REACT_THREE_" .. IMPOSTOR.name] = "ТРИ"
L["SABO_REACT_TWO_" .. IMPOSTOR.name] = "ДВА"
L["SABO_REACT_ONE_" .. IMPOSTOR.name] = "ОДИН"
L["SABO_REACT_PASS_" .. IMPOSTOR.name] = "Реактор стабилизирован!"
L["SABO_REACT_END_" .. IMPOSTOR.name] = "Хорошего дня!"
L["SABO_REACT_STRANGE_GAME_" .. IMPOSTOR.name] = "СТРАННАЯ ИГРА"
L["SABO_STAT_INFO_" .. IMPOSTOR.name] = "Саботаж закончится, когда {n} игроков будут находятся в зоне действия саботажной станции! Она выделена красным цветом!"

-- EVERYONE LOSES EVERYONE LOSES EVERYONE LOSES
L["win_losers"] = "ВСЕ ПРОИГРАЛИ"
L["hilite_win_losers"] = "ВСЕ ПРОИГРАЛИ"
L["ev_win_losers"] = "ВСЕ ПРОИГРАЛИ"