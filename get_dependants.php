<?php
declare(strict_types=1);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/db.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

// 🔹 Handle Authorization header robustly
$headers = getallheaders();
$authHeader = '';

if (isset($headers['Authorization'])) {
    $authHeader = $headers['Authorization'];
} elseif (isset($headers['authorization'])) {
    $authHeader = $headers['authorization'];
} elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
}

if (!$authHeader || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Authorization token missing"]);
    exit;
}

$jwt = $matches[1];
$secretKey = $_ENV['JWT_SECRET'] ?? 'your_secret_here'; // fallback for safety

try {
    $decoded = JWT::decode($jwt, new Key($secretKey, 'HS256'));
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Invalid or expired token"]);
    exit;
}

// ✅ Extract employee_id from decoded token
if (!isset($decoded->employee_id)) {
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Token missing employee_id"]);
    exit;
}

$employee_id = $decoded->employee_id;

try {
    $stmt = $pdo->prepare("SELECT * FROM dependents WHERE employee_id = ?");
    $stmt->execute([$employee_id]);
    $dependents = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["success" => true, "dependents" => $dependents]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error."]);
}
?>
