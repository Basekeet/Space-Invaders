;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-reader.ss" "lang")((modname space-invaders) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
(require 2htdp/universe)
(require 2htdp/image)

;; Space Invaders


;; Constants:

(define WIDTH  300)
(define HEIGHT 500)

(define INVADER-X-SPEED 1.5)  ;speeds (not velocities) in pixels per tick
(define INVADER-Y-SPEED 1.5)
(define TANK-SPEED 2)
(define MISSILE-SPEED 10)

(define HIT-RANGE 10)

(define INVADE-RATE 100)

(define BACKGROUND (empty-scene WIDTH HEIGHT))

(define INVADER
  (overlay/xy (ellipse 10 15 "outline" "blue")              ;cockpit cover
              -5 6
              (ellipse 20 10 "solid"   "blue")))            ;saucer

(define TANK
  (overlay/xy (overlay (ellipse 28 8 "solid" "black")       ;tread center
                       (ellipse 30 10 "solid" "green"))     ;tread outline
              5 -14
              (above (rectangle 5 10 "solid" "black")       ;gun
                     (rectangle 20 10 "solid" "black"))))   ;main body

(define TANK-HEIGHT/2 (/ (image-height TANK) 2))

(define MISSILE (ellipse 5 15 "solid" "red"))



;; Data Definitions:

(define-struct game (invaders missiles tank))
;; Game is (make-game  (listof Invader) (listof Missile) Tank)
;; interp. the current state of a space invaders game
;;         with the current invaders, missiles and tank position

;; Game constants defined below Missile data definition

#;
(define (fn-for-game s)
  (... (fn-for-loinvader (game-invaders s))
       (fn-for-lom (game-missiles s))
       (fn-for-tank (game-tank s))))



(define-struct tank (x dir))
;; Tank is (make-tank Number Integer[-1, 1])
;; interp. the tank location is x, HEIGHT - TANK-HEIGHT/2 in screen coordinates
;;         the tank moves TANK-SPEED pixels per clock tick left if dir -1, right if dir 1

(define T0 (make-tank (/ WIDTH 2) 1))   ;center going right
(define T1 (make-tank 50 1))            ;going right
(define T2 (make-tank 50 -1))           ;going left

#;
(define (fn-for-tank t)
  (... (tank-x t) (tank-dir t)))



(define-struct invader (x y dx))
;; Invader is (make-invader Number Number Number)
;; interp. the invader is at (x, y) in screen coordinates
;;         the invader along x by dx pixels per clock tick

(define I1 (make-invader 150 100 12))           ;not landed, moving right
(define I2 (make-invader 150 HEIGHT -10))       ;exactly landed, moving left
(define I3 (make-invader 150 (+ HEIGHT 10) 10)) ;> landed, moving right


#;
(define (fn-for-invader invader)
  (... (invader-x invader) (invader-y invader) (invader-dx invader)))


(define-struct missile (x y))
;; Missile is (make-missile Number Number)
;; interp. the missile's location is x y in screen coordinates

(define M1 (make-missile 150 300))                       ;not hit U1
(define M2 (make-missile (invader-x I1) (+ (invader-y I1) 10)))  ;exactly hit U1
(define M3 (make-missile (invader-x I1) (+ (invader-y I1)  5)))  ;> hit U1

#;
(define (fn-for-missile m)
  (... (missile-x m) (missile-y m)))



(define G0 (make-game empty empty T0))
(define G1 (make-game empty empty T1))
(define G2 (make-game (list I1) (list M1) T1))
(define G3 (make-game (list I1 I2) (list M1 M2) T1))

;; =================
;; Functions:

;; Game -> Game
;; start the world with ...
;; 
(define (main g)
  (big-bang g                   ; Game
    (on-tick   next-game)     ; Game -> Game
    (to-draw   render)   ; Game -> Image
    (stop-when end?)      ; Game -> Boolean
    (on-key    handle-key)))    ; Game KeyEvent -> Game

;; Game -> Game
;; produce the next game position

; Tests are commented out because the random function
; is used and we cannot predict the result. But you can
; remove the add-invader function and uncomment the tests
; (they work)

;(check-expect (next-game (make-game empty empty (make-tank 0 1)))
;              (make-game empty empty (make-tank TANK-SPEED 1)))
;(check-expect (next-game (make-game (list (make-invader 5 5 INVADER-X-SPEED))
;                                    (list (make-missile 100 100)
;                                          (make-missile 200 95))
;                                    (make-tank 100 -1)))
;              (make-game (list (make-invader (+ 5 INVADER-X-SPEED) (+ 5 INVADER-Y-SPEED) INVADER-X-SPEED))
;                         (list (make-missile 100 (- 100 MISSILE-SPEED))
;                               (make-missile 200 (- 95 MISSILE-SPEED)))
;                         (make-tank (- 100 TANK-SPEED) -1)))
;(check-expect (next-game (make-game (list (make-invader (- WIDTH INVADER-X-SPEED) 200 INVADER-X-SPEED)
;                                          (make-invader INVADER-X-SPEED 300 (- INVADER-X-SPEED))
;                                          (make-invader 100 100 (- INVADER-X-SPEED)))
;                                    (list (make-missile 100 0)
;                                          (make-missile 100 200))
;                                    (make-tank 0 -1)))
;              (make-game (list (make-invader WIDTH (+ 200 INVADER-Y-SPEED) (- INVADER-X-SPEED))
;                               (make-invader 0 (+ 300 INVADER-Y-SPEED) INVADER-X-SPEED)
;                               (make-invader (- 100 INVADER-X-SPEED) (+ 100 INVADER-Y-SPEED) (- INVADER-X-SPEED)))
;                         (list (make-missile 100 (- 200 MISSILE-SPEED)))
;                         (make-tank 0 -1)))
;(check-expect (next-game (make-game (list (make-invader 200 200 INVADER-X-SPEED)
;                                          (make-invader 100 100 (- INVADER-X-SPEED)))
;                                    (list (make-missile 100 100)
;                                          (make-missile 100 200))
;                                    (make-tank WIDTH 1)))
;              (make-game (list (make-invader (+ 200 INVADER-X-SPEED) (+ 200 INVADER-Y-SPEED) INVADER-X-SPEED))
;                         (list (make-missile 100 (- 200 MISSILE-SPEED)))
;                         (make-tank WIDTH 1)))

;(define (next-game g) (make-game empty empty (make-tank 0 1))) ;stub

(define (next-game g)
  (make-game (add-invader (next-invaders (game-invaders g)
                                         (game-missiles g)))
             (next-missiles (game-missiles g)
                            (game-invaders g))
             (next-tank (game-tank g))))

;; ListOfInvader -> ListOfInvader
;; Add a new invader with 5% chance

(define (add-invader loi)
  (if (< (random 100) 2)
      (cons (make-invader (random WIDTH) 0 INVADER-X-SPEED) loi)
      loi))

;; ListOfInvader ListOfMissiles -> ListOfInvader
;; produce list with invaders on next position.
;; Change these direction if their X val <= 0 or >= WIDTH.
;; Remove them if their position are on a HIT-RANGE by HIT-RANGE square with Missile
(check-expect (next-invaders empty empty) empty)
(check-expect (next-invaders (list (make-invader 5 5 INVADER-X-SPEED))
                             (list (make-missile 100 100)
                                   (make-missile 200 95)))
              (list (make-invader (+ 5 INVADER-X-SPEED) (+ 5 INVADER-Y-SPEED) INVADER-X-SPEED)))
(check-expect (next-invaders (list (make-invader (- WIDTH INVADER-X-SPEED) 200 INVADER-X-SPEED)
                                   (make-invader INVADER-X-SPEED 150 (- INVADER-X-SPEED))
                                   (make-invader 100 100 (- INVADER-X-SPEED)))
                             (list (make-missile 100 0)
                                   (make-missile 100 200)))
              (list (make-invader WIDTH (+ 200 INVADER-Y-SPEED) (- INVADER-X-SPEED))
                    (make-invader 0 (+ 150 INVADER-Y-SPEED) INVADER-X-SPEED)
                    (make-invader (- 100 INVADER-X-SPEED) (+ 100 INVADER-Y-SPEED) (- INVADER-X-SPEED))))
(check-expect (next-invaders (list (make-invader 200 200 INVADER-X-SPEED)
                                   (make-invader 100 100 (- INVADER-X-SPEED)))
                             (list (make-missile 100 100)
                                   (make-missile 100 200)))
              (list (make-invader (+ 200 INVADER-X-SPEED) (+ 200 INVADER-Y-SPEED) INVADER-X-SPEED)))

;(define (next-invaders loi lom) empty) ;stub

(define (next-invaders loi lom)
  (cond [(empty? loi) empty]
        [else
         (if (put-invader? (first loi) lom)
             (cons (next-invader (first loi))
                   (next-invaders (rest loi) lom))
             (next-invaders (rest loi) lom))]))

;; Invader ListOfMissile -> Boolean
;; produce true if invader's position not in square 2 for 2 positions of all missiles
(check-expect (put-invader? (make-invader 100 100 INVADER-X-SPEED)
                            (list (make-missile 200 200)
                                  (make-missile 10 10))) true)
(check-expect (put-invader? (make-invader 200 100 INVADER-X-SPEED)
                            (list (make-missile 200 100)
                                  (make-missile 10 10))) false)
(check-expect (put-invader? (make-invader 400 50 INVADER-X-SPEED)
                            (list (make-missile (- 400 HIT-RANGE) (+ 50 HIT-RANGE))
                                  (make-missile 10 10))) false)

;(define (put-invader? i lom) false) ;stub

(define (put-invader? i lom)
  (cond [(empty? lom) true]
        [else
         (and (or (> (invader-x i) (+ (missile-x (first lom)) HIT-RANGE))
                  (< (invader-x i) (- (missile-x (first lom)) HIT-RANGE))
                  (> (invader-y i) (+ (missile-y (first lom)) HIT-RANGE))
                  (< (invader-y i) (- (missile-y (first lom)) HIT-RANGE)))
              (put-invader? i (rest lom)))]))

;; Invader -> Invader
;; Change postion of given invader and
;; change it's direction if Invader x postion >= Width or <= 0
(check-expect (next-invader (make-invader 100 100 INVADER-X-SPEED))
              (make-invader (+ 100 INVADER-X-SPEED) (+ 100 INVADER-Y-SPEED) INVADER-X-SPEED))
(check-expect (next-invader (make-invader 200 300 (- INVADER-X-SPEED)))
              (make-invader (- 200 INVADER-X-SPEED) (+ 300 INVADER-Y-SPEED) (- INVADER-X-SPEED)))
(check-expect (next-invader (make-invader (- WIDTH INVADER-X-SPEED) 100 INVADER-X-SPEED))
              (make-invader WIDTH (+ 100 INVADER-Y-SPEED) (- INVADER-X-SPEED)))
(check-expect (next-invader (make-invader INVADER-X-SPEED 200 (- INVADER-X-SPEED)))
              (make-invader 0  (+ 200 INVADER-Y-SPEED) INVADER-X-SPEED))

;(define (next-invader i) (make-invader 0 0 INVADER-X-SPEED)) ;stub

(define (next-invader i)
  (make-invader (+ (invader-x i) (invader-dx i))
                (+ (invader-y i) INVADER-Y-SPEED)
                (if (or (>= (+ (invader-x i) (invader-dx i)) WIDTH)
                        (<= (+ (invader-x i) (invader-dx i)) 0))
                    (- (invader-dx i))
                    (invader-dx i))))

;; ListOfMissiles ListOfInvader -> ListOfMissile
;; produce list with missiles on next position.
;; Delete them if their y positio equals/less than 0
;; Remove them if their position are on a HIT-RANGE by HIT-RANGE square with Invader
(check-expect (next-missiles (list (make-missile 100 100)
                                   (make-missile 200 95))
                             (list (make-invader 5 5 INVADER-X-SPEED)))
              (list (make-missile 100 (- 100 MISSILE-SPEED))
                    (make-missile 200 (- 95 MISSILE-SPEED))))
(check-expect (next-missiles (list (make-missile 150 0)
                                   (make-missile 200 40))
                             (list (make-invader 5 5 INVADER-X-SPEED)))
              (list (make-missile 200 (- 40 MISSILE-SPEED))))
(check-expect (next-missiles (list (make-missile 150 300)
                                   (make-missile 250 400))
                             (list (make-invader 150 300 INVADER-X-SPEED)
                                   (make-invader 100 200 INVADER-X-SPEED)))
              (list (make-missile 250 (- 400 MISSILE-SPEED))))
(check-expect (next-missiles (list (make-missile 20 300)
                                   (make-missile 250 400))
                             (list (make-invader (- 250 HIT-RANGE) (+ 400 HIT-RANGE) INVADER-X-SPEED)
                                   (make-invader 100 200 INVADER-X-SPEED)))
              (list (make-missile 20 (- 300 MISSILE-SPEED))))

;(define (next-missiles lom loi) empty) ;stub

(define (next-missiles lom loi)
  (cond [(empty? lom) empty]
        [else
         (if (put-missile? (first lom) loi)
             (cons (next-missile (first lom))
                   (next-missiles (rest lom) loi))
             (next-missiles (rest lom) loi))]))

;; Missile ListOfInvader -> Boolean
;; produce true if missile's position not in square 2 for 2 positions of all Invaders
(check-expect (put-missile? (make-missile 100 100)
                            (list (make-invader 200 200 INVADER-X-SPEED)
                                  (make-invader 10 10 INVADER-X-SPEED))) true)
(check-expect (put-missile? (make-missile 200 100 )
                            (list (make-invader 200 100 INVADER-X-SPEED)
                                  (make-invader 10 10 INVADER-X-SPEED))) false)
(check-expect (put-missile? (make-missile 400 50)
                            (list (make-invader 10 10 INVADER-X-SPEED)
                                  (make-invader (- 400 HIT-RANGE) (+ 50 HIT-RANGE) INVADER-X-SPEED))) false)
(check-expect (put-missile? (make-missile 100 0)
                            (list (make-invader 200 200 INVADER-X-SPEED)
                                  (make-invader 10 10 INVADER-X-SPEED))) false)


;(define (put-missile? m loi) false) ;stub

(define (put-missile? m loi)
  (cond [(empty? loi) true]
        [else
         (and (or (> (missile-x m) (+ (invader-x (first loi)) HIT-RANGE))
                  (< (missile-x m) (- (invader-x (first loi)) HIT-RANGE))
                  (> (missile-y m) (+ (invader-y (first loi)) HIT-RANGE))
                  (< (missile-y m) (- (invader-y (first loi)) HIT-RANGE)))
              (> (missile-y m) 0)
              (put-missile? m (rest loi)))]))


;; Missile -> Missile
;; change postion of given Missile
;; delete if y position equals 0
(check-expect (next-missile (make-missile 100 150))
              (make-missile 100 (- 150 MISSILE-SPEED)))
(check-expect (next-missile (make-missile 200 300))
              (make-missile 200 (- 300 MISSILE-SPEED)))

;(define (next-missile i) i) ;stub

(define (next-missile i)
  (make-missile (missile-x i)
                (- (missile-y i) MISSILE-SPEED)))

;; Tank -> Tank
;; produce next tank position
(check-expect (next-tank (make-tank 0 1)) (make-tank TANK-SPEED 1))
(check-expect (next-tank (make-tank 100 1)) (make-tank (+ 100 TANK-SPEED) 1))
(check-expect (next-tank (make-tank 150 -1)) (make-tank (- 150 TANK-SPEED) -1))
(check-expect (next-tank (make-tank 0 -1)) (make-tank 0 -1))
(check-expect (next-tank (make-tank WIDTH 1)) (make-tank WIDTH 1))

;(define (next-tank t) (make-tank 0 1)) ;stub

(define (next-tank t)
  (make-tank (cond [(and (>= (tank-x t) WIDTH)
                         (= (tank-dir t) 1)) WIDTH]
                   [(and (<= (tank-x t) 0)
                         (= (tank-dir t) -1)) 0]
                   [else (+ (tank-x t)
                            (* (tank-dir t) TANK-SPEED))])
             (tank-dir t)))
              
;; Game -> Image
;; render game field
(check-expect (render G0) (place-image TANK (/ WIDTH 2) (- 500 TANK-HEIGHT/2) BACKGROUND))
(check-expect (render G1) (place-image TANK 50 (- 500 TANK-HEIGHT/2) BACKGROUND))
(check-expect (render G2) (place-image MISSILE 150 300
                                       (place-image INVADER 150 100
                                                    (place-image TANK 50 (- 500 TANK-HEIGHT/2) BACKGROUND))))

;(define (render g) BACKGROUND) ;stub

(define (render g)
  (render-missiles (game-missiles g)
                   (render-invaders (game-invaders g)
                                    (render-tank (game-tank g)
                                                 BACKGROUND))))

;; Tank Image -> Image
;; place tank on the Image
(check-expect (render-tank (make-tank 100 1) BACKGROUND)
              (place-image TANK 100 (- 500 TANK-HEIGHT/2) BACKGROUND))
(check-expect (render-tank (make-tank 150 -1) BACKGROUND)
              (place-image TANK 150 (- 500 TANK-HEIGHT/2) BACKGROUND))

;(define (render-tank t i) empty-image) ;stub

(define (render-tank t i)
  (place-image TANK (tank-x t) (- 500 TANK-HEIGHT/2) BACKGROUND))

;; ListOfInvader Image -> Image
;; place invaders on the image
(check-expect (render-invaders empty BACKGROUND) BACKGROUND)
(check-expect (render-invaders (list (make-invader 150 150 INVADER-X-SPEED)) BACKGROUND)
              (place-image INVADER 150 150 BACKGROUND))
(check-expect (render-invaders (list (make-invader 100 100 INVADER-X-SPEED)
                                     (make-invader 200 200 INVADER-X-SPEED)) BACKGROUND)
              (place-image INVADER 100 100 (place-image INVADER 200 200 BACKGROUND)))

;(define (render-invaders loi i) i) ;stub

(define (render-invaders loi i)
  (cond [(empty? loi) i]
        [else
         (place-image INVADER
                      (invader-x (first loi))
                      (invader-y (first loi))
                      (render-invaders (rest loi) i))]))

;; ListOfMissile Image -> Image
;; place missiles on the image
(check-expect (render-missiles empty BACKGROUND) BACKGROUND)
(check-expect (render-missiles (list (make-missile 100 200)) BACKGROUND)
              (place-image MISSILE 100 200 BACKGROUND))
(check-expect (render-missiles (list (make-missile 150 100)
                                     (make-missile 50 250)) BACKGROUND)
              (place-image MISSILE 50 250 (place-image MISSILE 150 100 BACKGROUND)))

;(define (render-missiles lom i) i) ;stub

(define (render-missiles lom i)
  (cond [(empty? lom) i]
        [else
         (place-image MISSILE
                      (missile-x (first lom))
                      (missile-y (first lom))
                      (render-missiles (rest lom) i))]))

;; Game KeyEvent -> Game
;; if Spacebar is pressed, add a missile in game at X position of tank an Y position equals HEIGHT
;; if left arrow is pressed change the direction of tank to -1
;; if right arrow is pressed change the direction of tank to 1
(check-expect (handle-key G0 "a") G0)
(check-expect (handle-key G0 " ") (make-game empty
                                             (list (make-missile (/ WIDTH 2) HEIGHT))
                                             (make-tank (/ WIDTH 2) 1)))
(check-expect (handle-key (make-game empty empty (make-tank 100 -1)) "left")
              (make-game empty empty (make-tank 100 -1)))
(check-expect (handle-key G0 "left") (make-game empty empty (make-tank (/ WIDTH 2) -1)))
(check-expect (handle-key G0 "right") (make-game empty empty (make-tank (/ WIDTH 2) 1)))
(check-expect (handle-key (make-game empty empty (make-tank 100 -1)) "right")
              (make-game empty empty (make-tank 100 1)))

(define (handle-key g ke)
  (cond [(key=? ke " ")
         (make-game (game-invaders g)
                    (add-missile (game-missiles g)
                                 (tank-x (game-tank g)))
                    (game-tank g))]
        [(key=? ke "left")
         (make-game (game-invaders g)
                    (game-missiles g)
                    (change-tank-dir (game-tank g) -1))]
        [(key=? ke "right")
         (make-game (game-invaders g)
                    (game-missiles g)
                    (change-tank-dir (game-tank g) 1))]
        [else g]))

;; ListOfMissile Number-> ListOfMissile
;; Add a missile in game at X postion equals x and Y position equals HEIGHT
(check-expect (add-missile empty 100) (list (make-missile 100 HEIGHT)))
(check-expect (add-missile (list (make-missile 50 100)) 200) (list (make-missile 200 HEIGHT)
                                                                   (make-missile 50 100)))

;(define (add-missile lom x) lom) ;stub

(define (add-missile lom x)
  (cons (make-missile x HEIGHT) lom))

;; Tank Natural[-1,1]-> Tank
;; Change tank direction to dir
(check-expect (change-tank-dir (make-tank 20  1)  1) (make-tank 20  1))
(check-expect (change-tank-dir (make-tank 20 -1)  1) (make-tank 20  1))
(check-expect (change-tank-dir (make-tank 20 -1) -1) (make-tank 20 -1))
(check-expect (change-tank-dir (make-tank 20  1) -1) (make-tank 20 -1))

;(define (change-tank-dir t dir) t) ;stub

(define (change-tank-dir t dir)
  (make-tank (tank-x t) dir))

;; Game -> Boolean
;; produce true if y position of some invader >= HEIGHT
(check-expect (end? (make-game empty empty (make-tank 100 1))) false)
(check-expect (end? (make-game (list (make-invader 300 100 INVADER-X-SPEED)) empty
                               (make-tank 50 -1))) false)
(check-expect (end? (make-game (list (make-invader 200 50 INVADER-X-SPEED)
                                     (make-invader 50 HEIGHT INVADER-X-SPEED)) empty
                                                                               (make-tank 250 -1))) true)

;(define (end? g) false) ;stub

(define (end? g)
  (check-invaders (game-invaders g)))

;; ListOfInvader -> Boolean
;; produce true if y position of some invader >= HEIGHT
(check-expect (check-invaders empty) false)
(check-expect (check-invaders (list (make-invader 300 100 INVADER-X-SPEED))) false)
(check-expect (check-invaders (list (make-invader 200 50 INVADER-X-SPEED)
                                    (make-invader 50 HEIGHT INVADER-X-SPEED))) true)

;(define (check-invaders loi) false) ;stub

(define (check-invaders loi)
  (cond [(empty? loi) false]
        [else
         (or (>= (invader-y (first loi)) HEIGHT)
             (check-invaders (rest loi)))]))
