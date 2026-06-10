---
name: api-endpoint-factory
description: Use this skill to create, modify, or delete API endpoints and their associated domain logic. Follows the project's 4-layer onion architecture with concrete code templates for each layer.
---

# API Endpoint Factory

Step-by-step guide to create a new CRUD endpoint in the goland-api project.

## Mandatory Architecture

```
Domain (internal/domain/) → Repository (internal/repository/) → Service (internal/service/) → Handler (internal/transport/http/) → Router (router.go) → DI (cmd/server/main.go)
```

## Step-by-Step: Creating a New Entity "Xxx"

### Step 1: Domain Model

**File**: `internal/domain/xxx_model.go`

```go
package domain

import (
    "time"
    "gorm.io/gorm"
)

type Xxx struct {
    ID        uint32         `gorm:"primaryKey" json:"id"`
    Name      string         `gorm:"size:100;not null" json:"name"`
    // ... entity-specific fields ...
    CreatedAt time.Time      `gorm:"not null" json:"created_at"`
    UpdatedAt time.Time      `gorm:"not null" json:"updated_at"`
    DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

type XxxQueryParams struct {
    Page     int
    PageSize int
    Search   string
}

type XxxListResponse struct {
    Items      []Xxx `json:"items"`
    Total      int64 `json:"total"`
    Page       int   `json:"page"`
    PageSize   int   `json:"page_size"`
    TotalPages int   `json:"total_pages"`
}
```

### Step 2: Domain Interface

**File**: `internal/domain/interfaces.go` — append:

```go
type XxxRepo interface {
    Create(ctx context.Context, x *Xxx) error
    GetByID(ctx context.Context, id uint32) (*Xxx, error)
    ListWithParams(ctx context.Context, params XxxQueryParams) (*XxxListResponse, error)
    Update(ctx context.Context, x *Xxx) error
    Delete(ctx context.Context, id uint32) error
}
```

### Step 3: Register Migration

**File**: `internal/domain/0_models.go` — add to `TablesToMigrate`:

```go
var TablesToMigrate []interface{} = []interface{}{
    // ... existing ...
    &Xxx{},
}
```

### Step 4: Repository

**File**: `internal/repository/gorm_xxx.go`

```go
package repository

import (
    "context"
    "errors"
    "math"
    "strings"

    "github.com/DavidRomaniuk/golang-api/internal/domain"
    "gorm.io/gorm"
)

type GormXxxRepository struct {
    db *gorm.DB
}

func NewGormXxxRepository(db *gorm.DB) domain.XxxRepo {
    return &GormXxxRepository{db}
}

func (r *GormXxxRepository) Create(ctx context.Context, x *domain.Xxx) error {
    return r.db.WithContext(ctx).Create(x).Error
}

func (r *GormXxxRepository) GetByID(ctx context.Context, id uint32) (*domain.Xxx, error) {
    var x domain.Xxx
    err := r.db.WithContext(ctx).First(&x, id).Error
    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, errors.New(domain.ErrNotFoundItem)
        }
        return nil, err
    }
    return &x, nil
}

func (r *GormXxxRepository) ListWithParams(ctx context.Context, params domain.XxxQueryParams) (*domain.XxxListResponse, error) {
    var items []domain.Xxx
    var total int64

    query := r.db.WithContext(ctx).Model(&domain.Xxx{})

    if params.Search != "" {
        searchTerm := "%" + strings.ToLower(params.Search) + "%"
        query = query.Where("LOWER(name) LIKE ?", searchTerm)
    }

    if err := query.Count(&total).Error; err != nil {
        return nil, err
    }

    query = query.Order("name ASC")

    if params.PageSize > 0 {
        offset := (params.Page - 1) * params.PageSize
        query = query.Offset(offset).Limit(params.PageSize)
    }

    if err := query.Find(&items).Error; err != nil {
        return nil, err
    }

    totalPages := 0
    if params.PageSize > 0 {
        totalPages = int(math.Ceil(float64(total) / float64(params.PageSize)))
    }

    return &domain.XxxListResponse{
        Items:      items,
        Total:      total,
        Page:       params.Page,
        PageSize:   params.PageSize,
        TotalPages: totalPages,
    }, nil
}

func (r *GormXxxRepository) Update(ctx context.Context, x *domain.Xxx) error {
    return r.db.WithContext(ctx).Save(x).Error
}

func (r *GormXxxRepository) Delete(ctx context.Context, id uint32) error {
    return r.db.WithContext(ctx).Delete(&domain.Xxx{}, id).Error
}
```

### Step 5: Service

**File**: `internal/service/xxx_service.go`

```go
package service

import (
    "context"
    "errors"

    "github.com/DavidRomaniuk/golang-api/internal/domain"
)

type XxxService struct {
    repo domain.XxxRepo
}

func NewXxxService(repo domain.XxxRepo) *XxxService {
    return &XxxService{repo: repo}
}

func (s *XxxService) Create(ctx context.Context, x *domain.Xxx) error {
    if x.Name == "" {
        return errors.New(domain.ErrInvalidInput)
    }
    return s.repo.Create(ctx, x)
}

func (s *XxxService) GetByID(ctx context.Context, id uint32) (*domain.Xxx, error) {
    return s.repo.GetByID(ctx, id)
}

func (s *XxxService) ListWithParams(ctx context.Context, params domain.XxxQueryParams) (*domain.XxxListResponse, error) {
    if params.Page < 1 {
        params.Page = 1
    }
    if params.PageSize < 1 {
        params.PageSize = 10
    }
    if params.PageSize > 100 {
        params.PageSize = 100
    }
    return s.repo.ListWithParams(ctx, params)
}

func (s *XxxService) Update(ctx context.Context, x *domain.Xxx) error {
    if x.ID == 0 || x.Name == "" {
        return errors.New(domain.ErrInvalidInput)
    }
    return s.repo.Update(ctx, x)
}

func (s *XxxService) Delete(ctx context.Context, id uint32) error {
    if id == 0 {
        return errors.New(domain.ErrInvalidInput)
    }
    return s.repo.Delete(ctx, id)
}
```

### Step 6: Handler

**File**: `internal/transport/http/xxxHandler.go`

```go
package http

import (
    "net/http"
    "strconv"
    "time"

    "github.com/DavidRomaniuk/golang-api/internal/domain"
    "github.com/DavidRomaniuk/golang-api/internal/service"
    "github.com/gin-gonic/gin"
)

type XxxHandler struct {
    service *service.XxxService
}

func NewXxxHandler(service *service.XxxService) *XxxHandler {
    return &XxxHandler{service: service}
}

type XxxRequest struct {
    Name string `json:"name" binding:"required"`
    // ... entity-specific fields ...
}

func (h *XxxHandler) Create(c *gin.Context) {
    var req XxxRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    x := &domain.Xxx{
        Name: req.Name,
    }

    if err := h.service.Create(c.Request.Context(), x); err != nil {
        if err.Error() == domain.ErrAlreadyExists {
            c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, x)
}

func (h *XxxHandler) List(c *gin.Context) {
    page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
    pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
    search := c.Query("search")

    params := domain.XxxQueryParams{
        Page:     page,
        PageSize: pageSize,
        Search:   search,
    }

    response, err := h.service.ListWithParams(c.Request.Context(), params)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, response)
}

func (h *XxxHandler) GetByID(c *gin.Context) {
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid ID"})
        return
    }

    x, err := h.service.GetByID(c.Request.Context(), uint32(id))
    if err != nil {
        if err.Error() == domain.ErrNotFoundItem {
            c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, x)
}

func (h *XxxHandler) Update(c *gin.Context) {
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid ID"})
        return
    }

    var req XxxRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    x, err := h.service.GetByID(c.Request.Context(), uint32(id))
    if err != nil {
        if err.Error() == domain.ErrNotFoundItem {
            c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    x.Name = req.Name
    x.UpdatedAt = time.Now()

    if err := h.service.Update(c.Request.Context(), x); err != nil {
        c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, x)
}

func (h *XxxHandler) Delete(c *gin.Context) {
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid ID"})
        return
    }

    if err := h.service.Delete(c.Request.Context(), uint32(id)); err != nil {
        if err.Error() == domain.ErrNotFoundItem {
            c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusNoContent, nil)
}
```

### Step 7: Register Routes

**File**: `internal/transport/http/router.go`

Add service parameter to `NewRouter()`:

```go
func NewRouter(
    // ... existing services ...
    xs *service.XxxService,
) *gin.Engine {
```

Add route group inside `v1`:

```go
xxxRoutes := v1.Group("/xxx")
{
    h := NewXxxHandler(xs)
    xxxRoutes.Use(AuthMiddleware())
    xxxRoutes.GET("", h.List)
    xxxRoutes.GET("/:id", h.GetByID)
    xxxRoutes.POST("", RequireRoles(domain.RoleManager, domain.RoleAdmin), h.Create)
    xxxRoutes.PUT("/:id", RequireRoles(domain.RoleManager, domain.RoleAdmin), h.Update)
    xxxRoutes.DELETE("/:id", RequireRoles(domain.RoleAdmin), h.Delete)
}
```

### Step 8: Wire Dependencies

**File**: `cmd/server/main.go`

```go
// In main(), after existing repos:
xxxRepo := repository.NewGormXxxRepository(db.DB)
xxxService := service.NewXxxService(xxxRepo)

// Pass to router:
router := httpTransport.NewRouter(clientService, credentialsService, invoiceService, fireExtinguisherService, powderService, xxxService)
```

### Step 9: Seed Data

**File**: `internal/domain/jsons/xxx.json` — create with sample data.

**File**: `cmd/db/seeds.go` — add seeding logic.

## Checklist

- [ ] Domain model with audit fields (CreatedAt, UpdatedAt, DeletedAt)
- [ ] Domain interface in `interfaces.go`
- [ ] Model registered in `TablesToMigrate`
- [ ] Repository with `WithContext(ctx)` on ALL queries
- [ ] Service with pagination clamping and input validation
- [ ] Handler with proper error → HTTP status mapping
- [ ] Routes registered with `AuthMiddleware()` + `RequireRoles()`
- [ ] DI wiring in `main.go`
- [ ] Seed data in `jsons/` and `seeds.go`
- [ ] All comments in ENGLISH

## Contextual References

- `.opencode/context/api-contracts.md` — HTTP status codes, response format, pagination
- `.opencode/context/rules.md` — Development standards, error handling, security
- `.opencode/context/architecture.md` — Layer details, dependency flow
- `.opencode/context/naming-registry.md` — DB ↔ Go ↔ JSON type mapping
