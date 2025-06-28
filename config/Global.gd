extends Node


var gameStarted: bool

var playerBody: CharacterBody2D

var playerAlive :bool
var playerDamageZone: Area2D
var playerDamageAmount: int
var playerHitbox: Area2D

var telekinesis_mode := false
var camouflage := false
var time_freeze := false


var enemyADamageZone: Area2D
var enemyADamageAmount: int
var enemyAdealing: bool
var enemyAknockback := Vector2.ZERO





