;; Fleet Coordination Contract
;; Manages vehicle deployment and coordination

(define-map fleet-vehicles
  { vehicle-id: uint }
  {
    status: (string-ascii 20),
    current-zone: uint,
    assigned-route: uint,
    battery-level: uint,
    passenger-capacity: uint,
    current-passengers: uint
  }
)

(define-map deployment-zones
  { zone-id: uint }
  {
    name: (string-ascii 50),
    max-vehicles: uint,
    current-vehicles: uint,
    demand-level: uint
  }
)

(define-data-var next-zone-id uint u1)

;; Add vehicle to fleet
(define-public (add-to-fleet (vehicle-id uint) (passenger-capacity uint))
  (begin
    (map-set fleet-vehicles
      { vehicle-id: vehicle-id }
      {
        status: "available",
        current-zone: u0,
        assigned-route: u0,
        battery-level: u100,
        passenger-capacity: passenger-capacity,
        current-passengers: u0
      }
    )
    (ok true)
  )
)

;; Create deployment zone
(define-public (create-zone (name (string-ascii 50)) (max-vehicles uint))
  (let ((zone-id (var-get next-zone-id)))
    (map-set deployment-zones
      { zone-id: zone-id }
      {
        name: name,
        max-vehicles: max-vehicles,
        current-vehicles: u0,
        demand-level: u1
      }
    )
    (var-set next-zone-id (+ zone-id u1))
    (ok zone-id)
  )
)

;; Deploy vehicle to zone
(define-public (deploy-vehicle (vehicle-id uint) (zone-id uint))
  (match (map-get? fleet-vehicles { vehicle-id: vehicle-id })
    vehicle-data
    (match (map-get? deployment-zones { zone-id: zone-id })
      zone-data
      (if (< (get current-vehicles zone-data) (get max-vehicles zone-data))
        (begin
          (map-set fleet-vehicles
            { vehicle-id: vehicle-id }
            (merge vehicle-data { current-zone: zone-id, status: "deployed" })
          )
          (map-set deployment-zones
            { zone-id: zone-id }
            (merge zone-data { current-vehicles: (+ (get current-vehicles zone-data) u1) })
          )
          (ok true)
        )
        (err u400)
      )
      (err u404)
    )
    (err u404)
  )
)

;; Get fleet vehicle status
(define-read-only (get-vehicle-status (vehicle-id uint))
  (map-get? fleet-vehicles { vehicle-id: vehicle-id })
)

;; Get zone info
(define-read-only (get-zone (zone-id uint))
  (map-get? deployment-zones { zone-id: zone-id })
)
